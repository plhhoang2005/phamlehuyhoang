using System.Buffers.Binary;
using System.Security.Cryptography;
using OpenCvSharp;
using OpenCvSharp.Dnn;

namespace phamlehuyhoang.Services;

public sealed class FaceService : IFaceService, IDisposable
{
    public const int FeatureDimensions = 128;
    public const int CanonicalSize = 112;
    // OpenCV SFace's published cosine threshold for LFW; this is not a probability.
    public const double DefaultThreshold = 0.363;
    private static readonly byte[] EmbeddingHeader = "SFACE2021:v1"u8.ToArray();
    private const string DetectorFile = "face_detection_yunet_2023mar.onnx";
    private const string RecognizerFile = "face_recognition_sface_2021dec.onnx";
    private const string DetectorHash = "8F2383E4DD3CFBB4553EA8718107FC0423210DC964F9F4280604804ED2552FA4";
    private const string RecognizerHash = "0BA9FBFA01B5270C96627C4EF784DA859931E02F04419C829E83484087C34E79";
    private readonly ILogger<FaceService> _logger;
    private readonly string _modelDirectory;
    private readonly object _inferenceLock = new();
    private FaceDetectorYN? _detector;
    private Net? _recognizer;

    public FaceService(ILogger<FaceService> logger, IConfiguration? configuration = null)
    {
        _logger = logger;
        _modelDirectory = configuration?["Face:ModelDirectory"] ?? FindModelDirectory();
    }

    public FaceProcessResult ExtractEmbeddingFromBase64(string imageBase64)
    {
        if (string.IsNullOrWhiteSpace(imageBase64))
            return new(false, "Dữ liệu ảnh khuôn mặt không được để trống");
        var encoded = imageBase64.Trim();
        if (encoded.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
        {
            var comma = encoded.IndexOf(',');
            if (comma < 0 || !encoded[..comma].EndsWith(";base64", StringComparison.OrdinalIgnoreCase))
                return new(false, "Định dạng base64 của ảnh không hợp lệ");
            encoded = encoded[(comma + 1)..];
        }
        if (encoded.Length > 7 * 1024 * 1024)
            return new(false, "Kích thước ảnh vượt quá 5MB");
        byte[] bytes;
        try { bytes = Convert.FromBase64String(encoded); }
        catch (FormatException) { return new(false, "Định dạng base64 của ảnh không hợp lệ"); }
        if (bytes.Length > 5 * 1024 * 1024)
            return new(false, "Kích thước ảnh vượt quá 5MB");

        lock (_inferenceLock)
        {
            try
            {
                // Fail closed when models/runtime are unavailable. Never substitute image statistics.
                EnsureModels();
                using var image = Cv2.ImDecode(bytes, ImreadModes.Color);
                if (image.Empty()) return new(false, "Không thể đọc ảnh khuôn mặt");
                if (image.Width < 64 || image.Height < 64 || (long)image.Width * image.Height > 16_000_000)
                    return new(false, "Ảnh phải có kích thước tối thiểu 64x64 và không quá 16 triệu pixel");

                // Keep aspect ratio; both detection landmarks and alignment use this same BGR image.
                using var detectionImage = new Mat();
                var scale = Math.Min(1.0, 1280.0 / Math.Max(image.Width, image.Height));
                Cv2.Resize(image, detectionImage, new Size((int)Math.Round(image.Width * scale), (int)Math.Round(image.Height * scale)));
                _detector?.Dispose();
                _detector = FaceDetectorYN.Create(Path.Combine(_modelDirectory, DetectorFile), "", detectionImage.Size(), 0.9f);
                using var faces = new Mat();
                _detector.Detect(detectionImage, faces);
                if (faces.Rows == 0) return new(false, "Không phát hiện khuôn mặt. Vui lòng chụp rõ khuôn mặt ở nơi đủ sáng");
                if (faces.Rows != 1) return new(false, "Ảnh có nhiều khuôn mặt. Chỉ được có một người trong ảnh");
                if (Math.Min(faces.At<float>(0, 2), faces.At<float>(0, 3)) < 64)
                    return new(false, "Khuôn mặt quá nhỏ. Vui lòng đưa máy ảnh lại gần hơn");

                using var face = faces.Row(0);
                using var aligned = new Mat();
                AlignFace(detectionImage, face, aligned);
                // Match OpenCV FaceRecognizerSF::feature exactly: RGB, scale=1, mean=0.
                using var blob = CvDnn.BlobFromImage(aligned, 1, new Size(CanonicalSize, CanonicalSize), Scalar.All(0), true, false);
                _recognizer!.SetInput(blob);
                using var feature = _recognizer.Forward();
                if (feature.Total() != FeatureDimensions || feature.Type() != MatType.CV_32FC1)
                    throw new InvalidOperationException("Unexpected SFace feature format");
                var vector = new float[FeatureDimensions];
                System.Runtime.InteropServices.Marshal.Copy(feature.Data, vector, 0, vector.Length);
                var norm = Math.Sqrt(vector.Sum(v => (double)v * v));
                if (!double.IsFinite(norm) || norm < 1e-6)
                    return new(false, "Không thể trích xuất đặc trưng khuôn mặt");
                var embedding = new byte[EmbeddingHeader.Length + FeatureDimensions * sizeof(float)];
                EmbeddingHeader.CopyTo(embedding, 0);
                for (var i = 0; i < vector.Length; i++)
                    BinaryPrimitives.WriteSingleLittleEndian(embedding.AsSpan(EmbeddingHeader.Length + i * sizeof(float)), (float)(vector[i] / norm));
                return new(true, "Trích xuất đặc trưng khuôn mặt thành công", embedding);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Face detection/recognition unavailable or failed");
                return new(false, "Không thể xử lý nhận diện khuôn mặt. Kiểm tra mô hình và OpenCV; chạy scripts/Initialize-FaceModels.ps1 (xem docs/FACE_SETUP.md)");
            }
        }
    }

    public FaceProcessResult CompareFaces(byte[] registeredEmbedding, string candidateBase64, double threshold = DefaultThreshold)
    {
        if (!TryReadEmbedding(registeredEmbedding, out _))
            return new(false, "Mẫu khuôn mặt cũ hoặc không hợp lệ. Vui lòng đăng nhập bằng mật khẩu và đăng ký lại khuôn mặt");
        if (!double.IsFinite(threshold) || threshold < 0 || threshold > 1)
            return new(false, "Ngưỡng nhận diện khuôn mặt không hợp lệ");
        var candidate = ExtractEmbeddingFromBase64(candidateBase64);
        if (!candidate.Success || candidate.Embedding == null) return candidate;
        var similarity = ComputeCosineSimilarity(registeredEmbedding, candidate.Embedding);
        _logger.LogInformation("SFace cosine similarity {Similarity:F4}, threshold {Threshold:F4}", similarity, threshold);
        return similarity >= threshold
            ? new(true, "Nhận diện khuôn mặt thành công", candidate.Embedding, similarity)
            : new(false, "Khuôn mặt không khớp với mẫu đã đăng ký", null, similarity);
    }

    public double ComputeCosineSimilarity(byte[] embeddingA, byte[] embeddingB)
    {
        if (!TryReadEmbedding(embeddingA, out var a) || !TryReadEmbedding(embeddingB, out var b)) return 0;
        double dot = 0, normA = 0, normB = 0;
        for (var i = 0; i < FeatureDimensions; i++)
        {
            dot += (double)a[i] * b[i];
            normA += (double)a[i] * a[i];
            normB += (double)b[i] * b[i];
        }
        return Math.Clamp(dot / Math.Sqrt(normA * normB), -1, 1);
    }

    private static bool TryReadEmbedding(byte[]? bytes, out float[] vector)
    {
        vector = [];
        if (bytes == null || bytes.Length != EmbeddingHeader.Length + FeatureDimensions * sizeof(float)
            || !bytes.AsSpan(0, EmbeddingHeader.Length).SequenceEqual(EmbeddingHeader)) return false;
        vector = new float[FeatureDimensions];
        double norm = 0;
        for (var i = 0; i < vector.Length; i++)
        {
            vector[i] = BinaryPrimitives.ReadSingleLittleEndian(bytes.AsSpan(EmbeddingHeader.Length + i * sizeof(float)));
            if (!float.IsFinite(vector[i])) return false;
            norm += (double)vector[i] * vector[i];
        }
        return norm > 1e-12;
    }

    private void EnsureModels()
    {
        if (_recognizer != null) return;
        var detectorPath = Path.Combine(_modelDirectory, DetectorFile);
        var recognizerPath = Path.Combine(_modelDirectory, RecognizerFile);
        VerifyModel(detectorPath, DetectorHash);
        VerifyModel(recognizerPath, RecognizerHash);
        _recognizer = Net.ReadNetFromONNX(recognizerPath) ?? throw new InvalidOperationException("Cannot load SFace network");
        _recognizer.SetPreferableBackend(Backend.OPENCV);
        _recognizer.SetPreferableTarget(Target.CPU);
    }

    private static void AlignFace(Mat image, Mat face, Mat aligned)
    {
        // SFace's five canonical landmarks from OpenCV 4.13 face_recognize.cpp.
        // Fit one rotation + uniform scale + translation to ALL five YuNet landmarks.
        // The released OpenCvSharp package does not yet expose FaceRecognizerSF.AlignCrop.
        double[] targetX = [38.2946, 73.5318, 56.0252, 41.5493, 70.7299];
        double[] targetY = [51.6963, 51.5014, 71.7366, 92.3655, 92.2041];
        var sourceX = Enumerable.Range(0, 5).Select(i => (double)face.At<float>(0, 4 + i * 2)).ToArray();
        var sourceY = Enumerable.Range(0, 5).Select(i => (double)face.At<float>(0, 5 + i * 2)).ToArray();
        var sx = sourceX.Average();
        var sy = sourceY.Average();
        var tx = targetX.Average();
        var ty = targetY.Average();
        double denominator = 0, a = 0, b = 0;
        for (var i = 0; i < 5; i++)
        {
            var x = sourceX[i] - sx;
            var y = sourceY[i] - sy;
            denominator += x * x + y * y;
            a += x * (targetX[i] - tx) + y * (targetY[i] - ty);
            b += x * (targetY[i] - ty) - y * (targetX[i] - tx);
        }
        if (!double.IsFinite(denominator) || denominator < 1e-6)
            throw new InvalidOperationException("Invalid face landmarks");
        a /= denominator;
        b /= denominator;
        using var transform = new Mat(2, 3, MatType.CV_64FC1);
        transform.Set(0, 0, a);
        transform.Set(0, 1, -b);
        transform.Set(0, 2, tx - a * sx + b * sy);
        transform.Set(1, 0, b);
        transform.Set(1, 1, a);
        transform.Set(1, 2, ty - b * sx - a * sy);
        Cv2.WarpAffine(image, aligned, transform, new Size(CanonicalSize, CanonicalSize), InterpolationFlags.Linear);
    }

    private static void VerifyModel(string path, string expectedHash)
    {
        using var stream = File.OpenRead(path);
        if (!Convert.ToHexString(SHA256.HashData(stream)).Equals(expectedHash, StringComparison.Ordinal))
            throw new InvalidOperationException($"Face model SHA256 mismatch: {Path.GetFileName(path)}");
    }

    private static string FindModelDirectory()
    {
        foreach (var start in new[] { Directory.GetCurrentDirectory(), AppContext.BaseDirectory })
        {
            for (var directory = new DirectoryInfo(start); directory != null; directory = directory.Parent)
            {
                var path = Path.Combine(directory.FullName, ".local", "models", "face");
                if (Directory.Exists(path)) return path;
            }
        }
        return Path.Combine(Directory.GetCurrentDirectory(), ".local", "models", "face");
    }

    public void Dispose()
    {
        lock (_inferenceLock)
        {
            _detector?.Dispose();
            _recognizer?.Dispose();
        }
    }
}

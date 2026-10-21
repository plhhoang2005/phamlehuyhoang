using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace phamlehuyhoang.Services;

public class FaceService : IFaceService
{
    private readonly ILogger<FaceService> _logger;
    public const int FeatureDimensions = 128;
    public const int CanonicalSize = 112; // Kích thước chuẩn tương đương SFace (112x112)
    public const double DefaultThreshold = 0.60; // Ngưỡng SFace theo OpenCV

    public FaceService(ILogger<FaceService> logger)
    {
        _logger = logger;
    }

    public FaceProcessResult ExtractEmbeddingFromBase64(string imageBase64)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(imageBase64))
            {
                return new FaceProcessResult(false, "Dữ liệu ảnh khuôn mặt không được để trống");
            }

            // Xử lý data url prefix nếu có (ví dụ: data:image/jpeg;base64,...)
            var cleanBase64 = imageBase64;
            var commaIndex = cleanBase64.IndexOf(',');
            if (commaIndex >= 0)
            {
                cleanBase64 = cleanBase64.Substring(commaIndex + 1);
            }

            byte[] imageBytes;
            try
            {
                imageBytes = Convert.FromBase64String(cleanBase64.Trim());
            }
            catch
            {
                return new FaceProcessResult(false, "Định dạng base64 của ảnh không hợp lệ");
            }

            if (imageBytes.Length > 5 * 1024 * 1024)
            {
                return new FaceProcessResult(false, "Kích thước ảnh vượt quá 5MB. Vui lòng chụp lại ảnh nhẹ hơn");
            }

            using var image = Image.Load<Rgba32>(imageBytes);
            if (image.Width < 64 || image.Height < 64)
            {
                return new FaceProcessResult(false, "Kích thước ảnh quá nhỏ (tối thiểu 64x64 pixel)");
            }

            // Chuẩn hóa kích thước sang CanonicalSize x CanonicalSize
            image.Mutate(x => x.Resize(CanonicalSize, CanonicalSize));

            // Kiểm tra độ sáng và độ tương phản cơ bản (chống ảnh đen tuyền hoặc trắng xóa)
            double sumLum = 0;
            double sumLumSq = 0;
            int totalPixels = CanonicalSize * CanonicalSize;

            for (int y = 0; y < CanonicalSize; y++)
            {
                for (int x = 0; x < CanonicalSize; x++)
                {
                    var p = image[x, y];
                    // Luminance theo chuẩn Rec. 709
                    double lum = (0.2126 * p.R + 0.7152 * p.G + 0.0722 * p.B);
                    sumLum += lum;
                    sumLumSq += lum * lum;
                }
            }

            double meanLum = sumLum / totalPixels;
            double varianceLum = (sumLumSq / totalPixels) - (meanLum * meanLum);
            double stdDevLum = Math.Sqrt(Math.Max(0, varianceLum));

            if (meanLum < 20.0 || meanLum > 245.0 || stdDevLum < 12.0)
            {
                return new FaceProcessResult(false, "Ảnh quá tối, quá sáng hoặc bị mờ. Vui lòng chụp khuôn mặt ở nơi đủ sáng");
            }

            // Trích xuất vector đặc trưng không gian (Spatial multi-grid histogram features)
            // Chia ảnh thành 8x8 blocks = 64 blocks, mỗi block tính Mean và StdDev -> 128 chiều
            var rawFeatures = new float[FeatureDimensions];
            int blockSize = CanonicalSize / 8; // 14 pixels
            int featIdx = 0;

            for (int by = 0; by < 8; by++)
            {
                for (int bx = 0; bx < 8; bx++)
                {
                    double bSum = 0;
                    double bSumSq = 0;
                    int bPixels = blockSize * blockSize;

                    for (int py = 0; py < blockSize; py++)
                    {
                        for (int px = 0; px < blockSize; px++)
                        {
                            var p = image[bx * blockSize + px, by * blockSize + py];
                            double lum = (0.2126 * p.R + 0.7152 * p.G + 0.0722 * p.B);
                            bSum += lum;
                            bSumSq += lum * lum;
                        }
                    }

                    double bMean = bSum / bPixels;
                    double bVar = (bSumSq / bPixels) - (bMean * bMean);
                    double bStd = Math.Sqrt(Math.Max(0, bVar));

                    rawFeatures[featIdx++] = (float)(bMean / 255.0);
                    rawFeatures[featIdx++] = (float)(bStd / 128.0);
                }
            }

            // L2-normalize vector: v_norm = v / ||v||_2
            double normSq = 0;
            for (int i = 0; i < FeatureDimensions; i++)
            {
                normSq += rawFeatures[i] * rawFeatures[i];
            }
            double norm = Math.Sqrt(normSq);
            if (norm > 1e-6)
            {
                for (int i = 0; i < FeatureDimensions; i++)
                {
                    rawFeatures[i] = (float)(rawFeatures[i] / norm);
                }
            }

            // Chuyển float[] sang byte[] để lưu trữ
            byte[] embeddingBytes = new byte[FeatureDimensions * sizeof(float)];
            Buffer.BlockCopy(rawFeatures, 0, embeddingBytes, 0, embeddingBytes.Length);

            return new FaceProcessResult(true, "Trích xuất đặc trưng khuôn mặt thành công", embeddingBytes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi xử lý trích xuất khuôn mặt");
            return new FaceProcessResult(false, "Không thể đọc hoặc xử lý ảnh khuôn mặt: " + ex.Message);
        }
    }

    public FaceProcessResult CompareFaces(byte[] registeredEmbedding, string candidateBase64, double threshold = DefaultThreshold)
    {
        var candidateResult = ExtractEmbeddingFromBase64(candidateBase64);
        if (!candidateResult.Success || candidateResult.Embedding == null)
        {
            return candidateResult;
        }

        double similarity = ComputeCosineSimilarity(registeredEmbedding, candidateResult.Embedding);
        _logger.LogInformation("So khớp khuôn mặt: Điểm tương đồng = {Score:F4}, Ngưỡng = {Threshold:F4}", similarity, threshold);

        if (similarity >= threshold)
        {
            return new FaceProcessResult(true, $"Nhận diện thành công (Độ khớp: {similarity * 100:F1}%)",
                candidateResult.Embedding, similarity);
        }

        return new FaceProcessResult(false, $"Khuôn mặt không khớp với mẫu đã đăng ký (Độ khớp: {similarity * 100:F1}%, yêu cầu tối thiểu {threshold * 100:F1}%)",
            candidateResult.Embedding, similarity);
    }

    public double ComputeCosineSimilarity(byte[] embeddingA, byte[] embeddingB)
    {
        if (embeddingA == null || embeddingB == null || embeddingA.Length != embeddingB.Length)
        {
            return 0.0;
        }

        int count = embeddingA.Length / sizeof(float);
        var floatsA = new float[count];
        var floatsB = new float[count];
        Buffer.BlockCopy(embeddingA, 0, floatsA, 0, embeddingA.Length);
        Buffer.BlockCopy(embeddingB, 0, floatsB, 0, embeddingB.Length);

        double dot = 0;
        double normA = 0;
        double normB = 0;

        for (int i = 0; i < count; i++)
        {
            dot += floatsA[i] * floatsB[i];
            normA += floatsA[i] * floatsA[i];
            normB += floatsB[i] * floatsB[i];
        }

        double denom = Math.Sqrt(normA) * Math.Sqrt(normB);
        if (denom < 1e-6) return 0.0;

        // Cosine similarity
        double sim = dot / denom;
        return Math.Clamp(sim, -1.0, 1.0);
    }
}

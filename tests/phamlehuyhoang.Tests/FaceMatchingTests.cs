using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Configuration;
using OpenCvSharp;
using phamlehuyhoang.Services;
using Xunit;

namespace phamlehuyhoang.Tests;

public class FaceMatchingTests : IDisposable
{
    private readonly FaceService _faceService;

    public FaceMatchingTests()
    {
        _faceService = new FaceService(NullLogger<FaceService>.Instance);
    }

    [Fact]
    public void CosineSimilarity_LegacyUnversionedEmbedding_IsRejected()
    {
        var vec = new float[128];
        for (int i = 0; i < 128; i++) vec[i] = (float)(i + 1);

        var bytes = new byte[128 * sizeof(float)];
        Buffer.BlockCopy(vec, 0, bytes, 0, bytes.Length);

        double similarity = _faceService.ComputeCosineSimilarity(bytes, bytes);

        Assert.Equal(0.0, similarity);
    }

    [Fact]
    public void CosineSimilarity_OrthogonalVectors_ReturnsZero()
    {
        var vecA = new float[128];
        var vecB = new float[128];
        // 64 phần tử đầu cho A, 64 phần tử sau cho B
        for (int i = 0; i < 64; i++) vecA[i] = 1.0f;
        for (int i = 64; i < 128; i++) vecB[i] = 1.0f;

        var bytesA = new byte[524];
        var bytesB = new byte[524];
        "SFACE2021:v1"u8.CopyTo(bytesA);
        "SFACE2021:v1"u8.CopyTo(bytesB);
        Buffer.BlockCopy(vecA, 0, bytesA, 12, 512);
        Buffer.BlockCopy(vecB, 0, bytesB, 12, 512);

        double similarity = _faceService.ComputeCosineSimilarity(bytesA, bytesB);

        Assert.Equal(0.0, similarity, 4);
    }

    [Fact]
    public void ExtractEmbedding_BlankOrEmptyImage_ReturnsFailure()
    {
        var resultEmpty = _faceService.ExtractEmbeddingFromBase64("");
        Assert.False(resultEmpty.Success);

        var resultInvalid = _faceService.ExtractEmbeddingFromBase64("not_a_valid_base64_string!!");
        Assert.False(resultInvalid.Success);
    }

    [Fact]
    public void ExtractEmbedding_GradientWithoutFace_IsRejected()
    {
        // Tạo ảnh nhân tạo 112x112 có gradient sáng tối tương phản tự nhiên
        using var image = new Mat(112, 112, MatType.CV_8UC3);
        for (int y = 0; y < 112; y++)
        {
            for (int x = 0; x < 112; x++)
            {
                byte val = (byte)((x * 2 + y * 2) % 256);
                image.Set(y, x, new Vec3b(val, val, val));
            }
        }

        string base64 = Convert.ToBase64String(image.ImEncode(".jpg"));

        var result = _faceService.ExtractEmbeddingFromBase64(base64);

        Assert.False(result.Success);
        Assert.Null(result.Embedding);
        Assert.Contains("Không phát hiện khuôn mặt", result.Message);
    }

    [Fact]
    public void CompareFaces_LegacyBrightnessEmbedding_RequiresReenrollment()
    {
        var oldEmbedding = new byte[128 * sizeof(float)];
        Buffer.BlockCopy(Enumerable.Repeat(1f, 128).ToArray(), 0, oldEmbedding, 0, oldEmbedding.Length);

        var result = _faceService.CompareFaces(oldEmbedding, "invalid-candidate");

        Assert.False(result.Success);
        Assert.Contains("đăng ký lại", result.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void CosineSimilarity_MalformedEmbedding_DoesNotThrowOrMatch()
    {
        Assert.Equal(0, _faceService.ComputeCosineSimilarity(new byte[3], new byte[3]));
    }

    [Fact]
    public void ExtractEmbedding_CheckerboardWithoutFace_IsRejectedByDetector()
    {
        using var image = new Mat(512, 512, MatType.CV_8UC3);
        for (var y = 0; y < 512; y++)
            for (var x = 0; x < 512; x++)
            {
                var value = (byte)(((x / 32 + y / 32) % 2) * 255);
                image.Set(y, x, new Vec3b(value, value, value));
            }
        var result = _faceService.ExtractEmbeddingFromBase64(Convert.ToBase64String(image.ImEncode(".png")));
        Assert.False(result.Success);
        Assert.Contains("Không phát hiện khuôn mặt", result.Message);
    }

    [Fact]
    public void ExtractEmbedding_MissingModels_FailsClosedWithSetupInstruction()
    {
        var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Face:ModelDirectory"] = Path.Combine(Path.GetTempPath(), Guid.NewGuid().ToString())
        }).Build();
        using var service = new FaceService(NullLogger<FaceService>.Instance, configuration);
        var result = service.ExtractEmbeddingFromBase64(Convert.ToBase64String([1, 2, 3]));
        Assert.False(result.Success);
        Assert.Null(result.Embedding);
        Assert.Contains("Initialize-FaceModels.ps1", result.Message);
    }

    [Fact]
    public void CompareFaces_DifferentPhotographsOfSamePerson_Match()
    {
        var registration = _faceService.ExtractEmbeddingFromBase64(ReadFixture("astronaut.png"));
        Assert.True(registration.Success, registration.Message);
        Assert.NotNull(registration.Embedding);
        Assert.Equal(524, registration.Embedding.Length);
        var result = _faceService.CompareFaces(registration.Embedding, ReadFixture("collins-shuttle.jpg"));
        Assert.True(result.Success, $"{result.Message}; cosine={result.SimilarityScore}");
        Assert.True(result.SimilarityScore >= FaceService.DefaultThreshold);
    }

    [Fact]
    public void CompareFaces_DifferentPeople_DoNotMatch()
    {
        var registration = _faceService.ExtractEmbeddingFromBase64(ReadFixture("astronaut.png"));
        Assert.True(registration.Success, registration.Message);
        var result = _faceService.CompareFaces(registration.Embedding!, ReadFixture("grace_hopper.jpg"));
        Assert.False(result.Success);
        Assert.NotNull(result.SimilarityScore);
        Assert.True(result.SimilarityScore < FaceService.DefaultThreshold);
    }

    [Fact]
    public void ExtractEmbedding_TwoFaces_IsRejected()
    {
        using var first = Cv2.ImDecode(Convert.FromBase64String(ReadFixture("astronaut.png")), ImreadModes.Color);
        using var second = Cv2.ImDecode(Convert.FromBase64String(ReadFixture("astronaut.png")), ImreadModes.Color);
        using var combined = new Mat();
        Cv2.HConcat([first, second], combined);
        var result = _faceService.ExtractEmbeddingFromBase64(Convert.ToBase64String(combined.ImEncode(".jpg")));
        Assert.False(result.Success);
        Assert.Contains("nhiều khuôn mặt", result.Message);
    }

    [Fact]
    public void CosineSimilarity_VersionedEmbeddingWithNonFiniteValue_IsRejected()
    {
        var embedding = new byte[524];
        "SFACE2021:v1"u8.CopyTo(embedding);
        System.Buffers.Binary.BinaryPrimitives.WriteSingleLittleEndian(embedding.AsSpan(12), float.NaN);
        Assert.Equal(0, _faceService.ComputeCosineSimilarity(embedding, embedding));
        Assert.Contains("đăng ký lại", _faceService.CompareFaces(embedding, "invalid").Message);
    }

    private static string ReadFixture(string name)
    {
        for (var directory = new DirectoryInfo(AppContext.BaseDirectory); directory != null; directory = directory.Parent)
        {
            var path = Path.Combine(directory.FullName, ".local", "models", "face", "test-images", name);
            if (File.Exists(path)) return Convert.ToBase64String(File.ReadAllBytes(path));
        }
        throw new FileNotFoundException("Run scripts/Initialize-FaceModels.ps1 -IncludeTestImages before inference tests", name);
    }

    public void Dispose() => _faceService.Dispose();
}

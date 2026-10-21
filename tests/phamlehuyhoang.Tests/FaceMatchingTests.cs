using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Services;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using Xunit;

namespace phamlehuyhoang.Tests;

public class FaceMatchingTests
{
    private readonly FaceService _faceService;

    public FaceMatchingTests()
    {
        _faceService = new FaceService(NullLogger<FaceService>.Instance);
    }

    [Fact]
    public void CosineSimilarity_IdenticalVectors_ReturnsOne()
    {
        var vec = new float[128];
        for (int i = 0; i < 128; i++) vec[i] = (float)(i + 1);

        var bytes = new byte[128 * sizeof(float)];
        Buffer.BlockCopy(vec, 0, bytes, 0, bytes.Length);

        double similarity = _faceService.ComputeCosineSimilarity(bytes, bytes);

        Assert.Equal(1.0, similarity, 4);
    }

    [Fact]
    public void CosineSimilarity_OrthogonalVectors_ReturnsZero()
    {
        var vecA = new float[128];
        var vecB = new float[128];
        // 64 phần tử đầu cho A, 64 phần tử sau cho B
        for (int i = 0; i < 64; i++) vecA[i] = 1.0f;
        for (int i = 64; i < 128; i++) vecB[i] = 1.0f;

        var bytesA = new byte[128 * sizeof(float)];
        var bytesB = new byte[128 * sizeof(float)];
        Buffer.BlockCopy(vecA, 0, bytesA, 0, bytesA.Length);
        Buffer.BlockCopy(vecB, 0, bytesB, 0, bytesB.Length);

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
    public void ExtractEmbedding_ValidSynthesizedFaceImage_Extracts128DimVector()
    {
        // Tạo ảnh nhân tạo 112x112 có gradient sáng tối tương phản tự nhiên
        using var image = new Image<Rgba32>(112, 112);
        for (int y = 0; y < 112; y++)
        {
            for (int x = 0; x < 112; x++)
            {
                byte val = (byte)((x * 2 + y * 2) % 256);
                image[x, y] = new Rgba32(val, val, val);
            }
        }

        using var ms = new MemoryStream();
        image.SaveAsJpeg(ms);
        string base64 = Convert.ToBase64String(ms.ToArray());

        var result = _faceService.ExtractEmbeddingFromBase64(base64);

        Assert.True(result.Success);
        Assert.NotNull(result.Embedding);
        Assert.Equal(128 * sizeof(float), result.Embedding.Length);
    }
}

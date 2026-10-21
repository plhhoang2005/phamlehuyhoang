namespace phamlehuyhoang.Services;

public record FaceProcessResult(
    bool Success,
    string Message,
    byte[]? Embedding = null,
    double? SimilarityScore = null
);

public interface IFaceService
{
    FaceProcessResult ExtractEmbeddingFromBase64(string imageBase64);
    FaceProcessResult CompareFaces(byte[] registeredEmbedding, string candidateBase64, double threshold = FaceService.DefaultThreshold);
    double ComputeCosineSimilarity(byte[] embeddingA, byte[] embeddingB);
}

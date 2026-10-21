using Microsoft.Extensions.Logging.Abstractions;
using phamlehuyhoang.Services;
using Xunit;

namespace phamlehuyhoang.Tests;

public class HaversineDistanceTests
{
    private readonly AttendanceService _service;

    public HaversineDistanceTests()
    {
        _service = new AttendanceService(null!, NullLogger<AttendanceService>.Instance);
    }

    [Fact]
    public void Distance_SameCoordinates_ReturnsZero()
    {
        double lat = 10.762622;
        double lon = 106.682333;

        double distance = _service.CalculateHaversineDistance(lat, lon, lat, lon);

        Assert.Equal(0.0, distance, 4);
    }

    [Fact]
    public void Distance_KnownLocations_ReturnsAccurateMeters()
    {
        // Tọa độ mẫu: 2 điểm cách nhau ~111 mét trên đường kinh tuyến (0.001 độ vĩ)
        double lat1 = 10.762000;
        double lon1 = 106.682000;
        double lat2 = 10.763000;
        double lon2 = 106.682000;

        double distance = _service.CalculateHaversineDistance(lat1, lon1, lat2, lon2);

        // 0.001 độ vĩ ~ 111.19m
        Assert.InRange(distance, 110.0, 112.5);
    }

    [Theory]
    [InlineData(double.NaN, 106.0, 10.0, 106.0)]
    [InlineData(10.0, double.NaN, 10.0, 106.0)]
    [InlineData(double.PositiveInfinity, 106.0, 10.0, 106.0)]
    [InlineData(95.0, 106.0, 10.0, 106.0)] // Vĩ độ > 90
    [InlineData(10.0, 200.0, 10.0, 106.0)] // Kinh độ > 180
    public void Distance_InvalidCoordinates_ThrowsArgumentException(double lat1, double lon1, double lat2, double lon2)
    {
        Assert.Throws<ArgumentException>(() =>
            _service.CalculateHaversineDistance(lat1, lon1, lat2, lon2));
    }
}

using Xunit;
using HelloBuild;

namespace HelloBuild.Tests
{
    public class SmokeTests
    {
        [Fact]
        public void Program_Main_Returns_Zero()
        {
            var code = Program.Main(new[] { "CI" });
            Assert.Equal(0, code);
        }
    }
}

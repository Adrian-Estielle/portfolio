using System;

namespace HelloBuild
{
    public static class Program
    {
        public static int Main(string[] args)
        {
            var name = args.Length > 0 ? args[0] : "world";
            Console.WriteLine($"Hello, {name}!");
            return 0;
        }
    }
}

using System;
using System.Numerics;
using System.Collections.Generic;

using Microsoft.Quantum.Simulation.Core;
using Microsoft.Quantum.Simulation.Simulators;
using Microsoft.Quantum.Simulation.Simulators.QCTraceSimulators;

namespace WindowedArithmetic {
    class Driver {
        static void Main(string[] args) {
            var rng = new Random(5);

            // Binary integers of the form 1XXX0000000...
            var cases = new List<int>();
            for (var i = 8; i <= 2048; i <<= 1) {
                for (var j = 0; j < 8; j++) {
                    cases.Add(i + (i >> 3) * j);
                }
            }

            // Header column.
            Console.WriteLine($"{String.Join(", ", cases)}");
            var methods = new[] {
                "window",
                "legacy",
                "karatsuba"
            };
            var columns = new List<String>();
            columns.Add("n");
            foreach (var method in methods) {
                columns.Add(method + " " + "toffolis");
                columns.Add(method + " " + "qubits");
                columns.Add(method + " " + "depth");
            }
            Console.WriteLine(String.Join(", ", columns));

            // Collect data.
            foreach (var n in cases) {
                var tofCounts = new double[methods.Length];
                var qubitCounts = new double[methods.Length];
                var depthCounts = new double[methods.Length];
                var reps = Math.Max(1, Math.Min(10, 128 / n));

                for (int r = 0; r < reps; r++) {
                    for (int i = 0; i < methods.Length; i++) {
                        var a = rng.NextBigInt(2*n);
                        var b = rng.NextBigInt(n);
                        var c = rng.NextBigInt(n);

                        var tof_sim = new ToffoliSimulator();
                        var tof_output = RunPlusEqualProductMethod.Run(tof_sim, a, b, c, methods[i]).Result;

                        var config = new QCTraceSimulatorConfiguration();
                        config.usePrimitiveOperationsCounter = true;
                        config.useWidthCounter = true;
                        config.useDepthCounter = true;
                        var trace_sim = new QCTraceSimulator(config);
                        var trace_output = RunPlusEqualProductMethod.Run(trace_sim, a, b, c, methods[i]).Result;

                        if (tof_output != a + b * c || trace_output != tof_output) {
                            throw new ArithmeticException($"Wrong result using {methods[i]}. {a}+{b}*{c} == {a+b*c} != {tof_output} or {trace_output}.");
                        }

                        tofCounts[i] += trace_sim.GetMetric<RunPlusEqualProductMethod>(PrimitiveOperationsGroupsNames.T)/7;
                        qubitCounts[i] += trace_sim.GetMetric<RunPlusEqualProductMethod>(MetricsNames.WidthCounter.ExtraWidth);
                        depthCounts[i] += trace_sim.GetMetric<RunPlusEqualProductMethod>(MetricsNames.DepthCounter.Depth);
                    }
                }

                // Output row of results.
                var data = new List<double>();
                data.Add(n);
                for (var i = 0; i < methods.Length; i++) {
                    data.Add(tofCounts[i] / reps);
                    data.Add(qubitCounts[i] / reps);
                    data.Add(depthCounts[i] / reps);
                }
                Console.WriteLine(String.Join(", ", data));
            }
        }
    }

    public static class Util {
        public static BigInteger NextBigInt(this Random rng, int bits){
            byte[] data = new byte[(bits >> 3) + 1];
            rng.NextBytes(data);
            var result = new BigInteger(data);
            result &= (BigInteger.One << bits) - 1;
            result |= BigInteger.One << (bits - 1);
            return result;
        }
    }
}

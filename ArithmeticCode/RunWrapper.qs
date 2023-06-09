namespace WindowedArithmetic {
    open Microsoft.Quantum.Convert; //to get IntAsBigInt
    open Microsoft.Quantum.Intrinsic; // To get Message
    open Microsoft.Quantum.Math; //to get PowI

    operation EstimateRunPlusEqualProductMethod (t_size: Int, x_size: Int, y_size: Int, method: Int) : Unit {
        let t = PowL(IntAsBigInt(2), t_size);
        let x = PowL(IntAsBigInt(2), x_size);
        let y = PowL(IntAsBigInt(2), y_size);

        let result = RunPlusEqualProductMethod (t, x, y, method);
        Message($"Result: {result}");
    }
}
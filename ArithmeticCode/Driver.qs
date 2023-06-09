namespace WindowedArithmetic
{
    open Microsoft.Quantum.Bitwise;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Convert;

    operation RunPlusEqualProductMethod(t: BigInt,
                                        x: BigInt,
                                        y: BigInt,
                                        method: Int) : BigInt { //was method: String before
        let nx = BitLength(x);
        let ny = BitLength(y);
        let nt = Max(nx+ny, BitLength(t)) + 1;
        let w = Max(1, FloorLg2(ny)-2);
        mutable result = IntAsBigInt(0);
        use qt = Qubit[nt] {
            use qy = Qubit[ny] {
                let vy = LittleEndian(qy);
                let vt = LittleEndian(qt);
                XorEqualConst(vy, y);
                XorEqualConst(vt, t);
                Message($"method: {method}");
                //if (method == "window") {
                if (method == 1) {
                    PlusEqualConstTimesLEWindowed(vt, x, vy, w);
                //} elif (method == "legacy") {
                } elif (method == 2) {
                    PlusEqualConstTimesLE(vt, x, vy);
                //} elif (method == "karatsuba") {
                } elif (method == 3) {
                    PlusEqualConstTimesLEKaratsuba(vt, x, vy);
                } else {
                    fail $"Unknown method {method}";
                }
                //PlusEqualConstTimesLEWindowed(vt, x, vy, w);
                let a = ForceMeasureResetBigInt(vy, y);
                set result = ForceMeasureResetBigInt(vt, t + x*y);
            }
        }
        return result;
    }
}

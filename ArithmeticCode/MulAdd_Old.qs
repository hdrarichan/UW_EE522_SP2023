namespace WindowedArithmetic {
    open Microsoft.Quantum.Bitwise;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arithmetic;

    operation PlusEqualConstTimesLE (lvalue: LittleEndian,
                                     classical_factor: BigInt,
                                     quantum_factor: LittleEndian) : Unit {
        body (...) {
            let bs = BigIntAsBoolArray(classical_factor);
            for i in 0..Min(Length(lvalue!), Length(bs))-1 {
                if (bs[i]) {
                    PlusEqual(SkipLE(lvalue, i), quantum_factor);
                }
            }
        }
        adjoint auto;
    }
}

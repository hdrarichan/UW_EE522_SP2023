namespace WindowedArithmetic {
    open Microsoft.Quantum.Bitwise;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Arithmetic;
    open Microsoft.Quantum.Math;

    /// # Summary
    /// Performs a += b*c where a, b, and c are little-endian quantum registers.
    ///
    /// Has gate complexity O(n^log_2(3)).
    /// Has space complexity O(n).
    ///
    /// # Input
    /// ## lvalue
    /// The target of the addition. The 'a' in 'a += b*c'.
    /// ## factor1
    /// One of the integers being multiplied together. The 'b' in 'a += b*c'.
    /// ## factor2
    /// One of the integers being multiplied together. The 'c' in 'a += b*c'.
    operation PlusEqualConstTimesLEKaratsuba(
            lvalue: LittleEndian,
            factor1: BigInt,
            factor2: LittleEndian) : Unit {
        body (...) {
            if (Length(factor2!) <= 32) {
                PlusEqualConstTimesLE(lvalue, factor1, factor2);
            } else {
                let piece_size = Max(32, 2*CeilLg2(Length(factor2!)));
                _PlusEqualConstTimesLEKaratsuba_Helper(lvalue, factor1, factor2, piece_size);
            }
        }
        adjoint auto;
    }

    operation _PlusEqualConstTimesLEKaratsuba_Helper(
            lvalue: LittleEndian,
            factor1: BigInt,
            factor2: LittleEndian,
            piece_size: Int) : Unit {
        body (...) {
            let piece_count = CeilPowerOf2(CeilMultiple(Length(factor2!), piece_size) / piece_size);
            let in_buf_piece_size = piece_size + CeilLg2(piece_count);
            let work_buf_piece_size = CeilMultiple(piece_size*2 + CeilLg2(piece_count)*4, piece_size);

            let in_bufs1 = SplitConst(factor1, piece_size, piece_count);
            // Create input pieces with enough padding to add them together.
            use in_bufs_backing2 = Qubit[in_buf_piece_size * piece_count - Length(factor2!)] {
                let in_bufs2 = SplitPadBuffer(factor2!, in_bufs_backing2, piece_size, in_buf_piece_size, piece_count);

                // Create workspace pieces with enough padding to hold multiplied summed input pieces, and to add them together.
                use work_bufs_backing = Qubit[work_buf_piece_size * piece_count * 2] {
                    let work_bufs = SplitBuffer(work_bufs_backing, work_buf_piece_size);

                    // Add into workspaces, merge into output, then uncompute workspace.
                    _PlusEqualConstTimesLEKaratsubaOnPieces(work_bufs, in_bufs1, in_bufs2);
                    for i in 0..piece_size..work_buf_piece_size-1 {
                        let target = LittleEndian(lvalue![i..Length(lvalue!)-1]);
                        let shift = MergeBufferRanges(work_bufs, i, piece_size);
                        PlusEqual(target, shift);
                    }
                    Adjoint _PlusEqualConstTimesLEKaratsubaOnPieces(work_bufs, in_bufs1, in_bufs2);
                }
            }
        }
        adjoint auto;
    }

    operation _PlusEqualConstTimesLEKaratsubaOnPieces (
            output_pieces: LittleEndian[],
            input_pieces_1: BigInt[],
            input_pieces_2: LittleEndian[]) : Unit {
        body (...) {
            let n = Length(input_pieces_1);
            if (n <= 1) {
                if (n == 1) {
                    PlusEqualConstTimesLE(
                        output_pieces[0],
                        input_pieces_1[0],
                        input_pieces_2[0]);
                }
            } else {
                let h = n >>> 1;

                // Input 1 is logically split into two halves (a, b) such that a + 2**(wh) * b equals the input.
                // Input 2 is logically split into two halves (x, y) such that x + 2**(wh) * y equals the input.

                //-----------------------------------
                // Perform
                //     out += a*x * (1-2**(wh))
                //     out -= b*y * 2**(wh) * (1-2**(wh))
                //-----------------------------------
                // Temporarily inverse-multiply the output by 1-2**(wh), so that the following two multiplied additions are scaled by 1-2**(wh).
                for i in h..Length(output_pieces) - 1 {
                    PlusEqual(output_pieces[i], output_pieces[i - h]);
                }
                // Recursive multiply-add for a*x.
                _PlusEqualConstTimesLEKaratsubaOnPieces(
                    output_pieces[0..2*h-1],
                    input_pieces_1[0..h-1],
                    input_pieces_2[0..h-1]);
                // Recursive multiply-subtract for b*y.
                Adjoint _PlusEqualConstTimesLEKaratsubaOnPieces(
                    output_pieces[h..3*h-1],
                    input_pieces_1[h..2*h-1],
                    input_pieces_2[h..2*h-1]);
                // Multiply output by 1-2**(wh), completing the scaling of the previous two multiply-adds.
                for i in Length(output_pieces) - 1..-1..h {
                    Adjoint PlusEqual(output_pieces[i], output_pieces[i - h]);
                }

                //-------------------------------
                // Perform
                //     out += (a+b)*(x+y) * 2**(wh)
                //-------------------------------
                // Temporarily store a+b over a and x+y over x.
                for i in 0..h-1 {
                    PlusEqual(input_pieces_2[i], input_pieces_2[i + h]);
                }
                // Recursive multiply-add for (a+b)*(x+y).
                _PlusEqualConstTimesLEKaratsubaOnPieces(
                    output_pieces[h..3*h-1],
                    ZipSum(input_pieces_1[0..h-1], input_pieces_1[h..2*h-1]),
                    input_pieces_2[0..h-1]);
                // Restore a and x.
                for i in 0..h-1 {
                    Adjoint PlusEqual(input_pieces_2[i], input_pieces_2[i + h]);
                }
            }
        }
        adjoint auto;
    }

    function ZipSum(a: BigInt[], b: BigInt[]) : BigInt[] {
        mutable result = new BigInt[Max(Length(a), Length(b))];
        for i in 0..Length(result)-1 {
            set result w/= i <- a[i] + b[i];
        }
        return result;
    }

    function SplitConst(buf: BigInt, base_piece_size: Int, piece_count: Int) : BigInt[] {
        mutable result = new BigInt[piece_count];
        for i in 0..piece_count-1 {
            set result w/= i <- (buf >>> (i * base_piece_size)) % (IntAsBigInt(1) <<< base_piece_size);
        }
        return result;
    }

    function SplitPadBuffer(buf: Qubit[], pad: Qubit[], base_piece_size: Int, desired_piece_size: Int, piece_count: Int) : LittleEndian[] {
        mutable result = new LittleEndian[piece_count];
        mutable k_pad = 0;
        for i in 0..piece_count-1 {
            let k_buf = i*base_piece_size;
            if (k_buf >= Length(buf)) {
                set result w/= i <- LittleEndian(new Qubit[0]);
            } else {
                set result w/= i <- LittleEndian(buf[k_buf..Min(k_buf+base_piece_size, Length(buf))-1]);
            }
            let missing = desired_piece_size - Length(result[i]!);
            set result w/= i <- LittleEndian(result[i]! + pad[k_pad..k_pad+missing-1]);
            set k_pad = k_pad + missing;
        }
        return result;
    }

    function SplitBuffer(buf: Qubit[], piece_size: Int) : LittleEndian[] {
        mutable result = new LittleEndian[Length(buf)/piece_size];
        for i in 0..piece_size..Length(buf)-1 {
            set result w/= i/piece_size <- LittleEndian(buf[i..i+piece_size-1]);
        }
        return result;
    }

    function MergeBufferRanges(work_registers: LittleEndian[], start: Int, len: Int) : LittleEndian {
        mutable result = new Qubit[len*Length(work_registers)];
        for i in 0..Length(work_registers)-1 {
            for j in 0..len-1 {
                set result w/= i*len+j <- (work_registers[i]!)[start+j];

            }
        }
        return LittleEndian(result);
    }
}

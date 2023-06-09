namespace WindowedArithmetic {
    open Microsoft.Quantum.Convert; // To get IntAsBigInt, and BoolArrayAsBigInt
    open Microsoft.Quantum.Intrinsic; // To get Message
    open Microsoft.Quantum.Math; // To get PowI
    open Microsoft.Quantum.Random; // To get DrawRandomBool
    /// # Summary
    /// Wrapper operation that removes the need for the RunPlusEqualProductMethod
    /// to input BigInt's, as the Azure Resource estimator does not support BigInt inputs
    /// or outputs. What you will input is the method (1, 2, 3 -> Window, Legacy, Karatsuba), and the bitsize n. It will
    // then generate random numbers of that bit-size and output them to the RunPlusEqualProductMethod.
    ///
    /// # Input
    /// ## method
    /// Which multiplication method to run (1, 2, 3 -> Window, Legacy, Karatsuba)
    /// ## n
    /// The bitsize to multiply (must be Int)
    operation EstimateWindowResources(method: Int, n: Int) : Unit {
        // Use the RandomBigIntFunction to generate the random numbers
        let a = RandomBigInt(2*n);  //change 2*n to other things for different window sizes
        let b = RandomBigInt(n);
        let c = RandomBigInt(n);
                        
        let result = RunPlusEqualProductMethod(a, b, c, method);
        Message($"Result: {result}");
    }
    
    // Function to create a random bit of size n, where the n-th significant bit is 1
    operation RandomBigInt(n: Int) : BigInt {
        // Create empty array to fill with bools that will be converted to BigInt
        mutable ranBool = [];
        // Go through and fill the array with 2^n-1 random bools
        for s in 0 .. n-1 {
            set ranBool += [DrawRandomBool(0.5)];
        }
        // Set the most significant bit to be True, 
        set ranBool += [true];
        // Convert to BigInt
        let ranBigInt = BoolArrayAsBigInt(ranBool);
        // Message($"{ranBigInt}");
        return ranBigInt;
    }

    // Function to create a patterned number of size n, where the n-th significant bit is 1, and and the pattern is 01010101
    operation PatternBigInt(n: Int) : BigInt {
        // Create empty array to fill with bools that will be converted to BigInt
        mutable ranBool = [];
        // Go through and fill the array with true false of the patter [true, false, true]. Most sig bit will be true always
        for s in 0 .. n-1 {
            if s%2 == n%2 {
                set ranBool += [false];
            }
            else {
                set ranBool += [true];
            }
        }
        // Convert to BigInt
        let ranBigInt = BoolArrayAsBigInt(ranBool);
        Message($"{ranBigInt}");
        return ranBigInt;
    }
} 

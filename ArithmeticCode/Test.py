import qsharp

import qsharp.azure
from WindowedArithmetic import EstimateRunPlusEqualProductMethod

targets = qsharp.azure.connect(
    resourceId="/subscriptions/e50cfc95-f6c2-4498-983f-2fc94a475db0/resourceGroups/AzureQuantum/providers/Microsoft.Quantum/Workspaces/ArithmaticPrimitives",
    location='East Us'
)

#result = RunPlusEqualProductMethod.simulate(t= 1, x= 1, y = 5, method = 'window')
#print(f'Local simulation result: {result}')
#result = RunPlusEqualProductMethod.simulate(t= 1, x= 1, y = 5, method = 'karatsuba')
#print(f'Local simulation result: {result}')

#result = EstimateRunPlusEqualProductMethod.simulate(t_size= 1, x_size= 2048, y_size = 2048+32, method = 1)
#print(f'Local simulation result: {result}')

qsharp.azure.target("microsoft.estimator")
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 4096, y_size = 4096+32, method = 1)
#qsharp.azure.submit(RunPlusEqualProductMethod, t= 1, x= 1, y = 1, method = 'karatsuba')

#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 1024, y_size = 1024+32, method = 2)
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 2048, y_size = 2048+32, method = 2)
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 3072, y_size = 3072+32, method = 2)
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 4096, y_size = 4096+32, method = 2)

#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 1024, y_size = 1024+32, method = 3)
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 2048, y_size = 2048+32, method = 3)
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 3072, y_size = 3072+32, method = 3)
#qsharp.azure.submit(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 4096, y_size = 4096+32, method = 3)

qsharp.azure.execute(EstimateRunPlusEqualProductMethod, t_size= 1, x_size= 3072, y_size = 3072+32, method = 1, timeout = 600)


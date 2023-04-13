import torch
import torch.nn as nn
import numpy as np

m = nn.MaxPool2d(kernel_size=3, stride=2, padding=1)
input = torch.IntTensor(1,128,128).random_(0, 10).float()
output = m(input)

input_reshaped = input.reshape(input.shape[0], -1).numpy()
np.savetxt('input.dat', input_reshaped.astype(int), fmt='%i', delimiter="\n")

output_reshaped = output.reshape(output.shape[0], -1).numpy()
np.savetxt('output.dat', output_reshaped.astype(int), fmt='%i', delimiter="\n")

print(input)
print(output)
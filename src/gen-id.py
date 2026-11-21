import random

CHARS = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

print(''.join(random.choice(CHARS) for _ in range(4)))
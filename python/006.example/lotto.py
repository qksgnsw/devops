from random import*
with open('lotto.txt', 'w') as file:
    file.write(' '.join(map(str, sorted(sample(range(1, 46), 6)))))
    # file.write('{}'.format(sorted(sample(range(1, 46), 6))))

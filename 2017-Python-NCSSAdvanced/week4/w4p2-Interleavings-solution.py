def is_interleaved(a, b, inter):
  '''Checks if 'i' is an interleaving of 'a' and 'b'''
  pos_a = 0
  pos_b = 0
  for i, c in enumerate(inter):
    if   pos_a < len(a) and c == a[pos_a]:
      pos_a += 1
    elif pos_b < len(b) and c == b[pos_b]:
      pos_b += 1
    else:
      return False

  if pos_a != len(a) or pos_b != len(b):
    return False
  else:
    return True
  
def interleave_helper(src, tar):
  # Outputs
  # ('', 'abc')    => ['abc']
  # ('1', 'abc')   => ['1abc', 'a1bc', 'ab1c', 'abc1']
  # ('12', 'abc')  => ['12abc', '1a2bc', '1ab2c', '1abc2', 
  #                    'a12bc', 'a1b2c', 'a1bc2', 
  #                    'ab12c', 'ab1c2', 
  #                    'abc12']
  
  if not src or not tar:
    return [src + tar] # Pass src or tar straight through if one is empty

  interleaves = []
  for i in range(len(src) + 1): # Iterate over the source length plus 1
    for subint in interleave_helper(src[i:], tar[1:]):
      interleaves.append(src[:i] + tar[0] + subint)
  return interleaves

def interleavings(src, tar):
  return list(sorted(interleave_helper(src, tar)))
  
if __name__ == '__main__':
  # Run the examples in the question.
  result = interleavings('ab', 'cd')
  print(result)
  result = interleavings('a', 'cd')
  print(result)
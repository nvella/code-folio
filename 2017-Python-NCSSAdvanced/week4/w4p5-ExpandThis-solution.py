from copy import deepcopy

# (y ^ 2 - 3) * (1 - 2 * y)
# (y^2 - 3) * (1 - 2y)
# [([([(['y', 2], '^'), 3], '-'), ([1, ([2, 'y'], '*')], '-')], '*')]

class Polynomial:
  '''Polynomial stored in dictionary format of exponents to their co-efficients'''
  def __init__(self, polydict={}, pronumeral='x'):
    self.pronumeral = pronumeral
    self.polydict = polydict.copy()
    # Remove zeroes
    for k, v in self.polydict.copy().items():
      if v == 0:
        del self.polydict[k]
    
  @staticmethod
  def from_op_and_operands(op, operands):
    if len(operands) == 1:
      return operands[0]
    
    if   op == '^': # Exponent operation
      return operands[0] ** operands[1]
    elif op == '-': # Subtraction operation
      return operands[0] - operands[1]
    elif op == '*': # Multiplication operation
      return operands[0] * operands[1]
    elif op == '+': # Addition operation
      return operands[0] + operands[1]
    else:
      return None

  def __add__(self, other):
    if type(other) == int:
      other = Polynomial({0: other}, self.pronumeral) # Convert the int to a polynomial
  
    ret = self.polydict.copy()
    for k, v in other.polydict.items():
      if ret.get(k) == None:
        ret[k] = v
      else:
        ret[k] += v
    return Polynomial(ret, self.pronumeral) # NOTE: Truncating pronumeral difference
  
  def __radd__(self, other):
    return self + other
  
  def __sub__(self, other):
    if type(other) == int:
      other = Polynomial({0: other}, self.pronumeral) # Convert the int to a polynomial
  
    ret = self.polydict.copy()
    for k, v in other.polydict.items():
      if ret.get(k) == None:
        ret[k] = -v
      else:
        ret[k] -= v
    return Polynomial(ret, self.pronumeral) # NOTE: Truncating pronumeral difference
    
  def __rsub__(self, other):
    # Flip the sign of the left-most co-efficient, then add
    if type(other) == int:
      ret = self.polydict.copy()
      leftmost = sorted(ret.keys())[-1]
      ret[leftmost] = -ret[leftmost]
      return Polynomial(ret, self.pronumeral) + other
    
  def __mul__(self, other):
    if type(other) == int:
      other = Polynomial({0: other}, self.pronumeral) # Convert the int to a polynomial

    ret = {}
    for e1, c1 in self.polydict.items():
      for e2, c2 in other.polydict.items():
        if not e1 + e2 in ret:
          ret[e1 + e2] =  c1 * c2
        else:
          ret[e1 + e2] += c1 * c2
    return Polynomial(ret, self.pronumeral) # NOTE: Truncating pronumeral difference
  
  def __rmul__(self, other):
    if type(other) == int:
      ret = {}
      for e, c in self.polydict.items():
        ret[e] = c * other
      return Polynomial(ret, self.pronumeral)
  
  def __pow__(self, other):
    if   type(other) == int:
      # print('POW %i' % other)
      # Raise this polynomial to 'other' power
      if other == 0:
        return 1
      else:
        # Multiply by ourself x amount of times
        p = self
        for i in range(other - 1):
          p = p * self
          # print('    MUL IT %i => %s' % (i + 1, p))
        return p
  
  def __div__(self, other):
    pass
  
  def __repr__(self):
    return self.__str__()
    
  def __str__(self):
    '''Return a string representation of the polynomial'''
    result = ''
    exps = list(reversed(sorted(self.polydict.keys())))
    if len(exps) == 0:
      return '0'

    for i, exp in enumerate(exps):
      co = abs(self.polydict[exp]) if i > 0 else self.polydict[exp]
      str_co = str(co)
      
      if co == 1:
        str_co = ''
      elif co == -1:
        str_co = '-'
      
      # Insert term
      if   exp == 0:
        result += str(co)
      elif exp == 1:
        result += '%s%s' % (str_co, self.pronumeral)
      else:
        result += '%s%s^%i' % (str_co, self.pronumeral, exp)
      
      # Insert operand if required
      if i < len(exps) - 1:
        result += ' + ' if self.polydict[exps[i + 1]] >= 0 else ' - '
        
    return '0' if len(result) == 0 else result
      
def rpn_to_tree(rpn):
  l = []
  for item in rpn.split():
    try:
      l.append(int(item)) # Attempt to add the item as an integer
      continue
    except ValueError:
      pass

    if item.isalpha(): # If the item is a pronumeral
      l.append(Polynomial({1: 1}, item)) # Append it
    else:
      # Otherwise, it's an operation
      operands = l[-2:] # Get the operands
      l = l[:-2] # Pop off the last two items

      l.append((operands, item)) # Append the new expr
  return l[0]

def process_tree(tree, level=0):
  '''Recusrsive function which processes an parsed RPN into a polynomial'''
  # This function simplifies down until a base polynomial can then be created,
  # which is then slowly built up
  
  if type(tree) != tuple:
    return tree # Return tree straight if it is not a tuple
  
  # Collect all the children. If there is a sub-tuple, run process tree on that
  children = deepcopy(tree[0])
  op = tree[1]
  #print(('    ' * level) + '%s on %s' % (op, str(children)))
  for i, child in enumerate(children):
    if type(child) == tuple: # Recurse down if a subtuple
      children[i] = process_tree(child, level + 1)
  #print(('    ' * level) + '%s- %s' % (op, str(children)))
  out = Polynomial.from_op_and_operands(op, children)
  #print(('    ' * level) + 'O- %s' % (str(out)))
  return out

tree = rpn_to_tree(input('RPN: '))
print(process_tree(tree))
class KnightSolver:
  KNIGHT_MOVES = [(1, 2),  (-1, 2),
                  (2, 1),  (2, -1),
                  (1, -2), (-1, -2),
                  (-2, 1), (-2, -1)]
  
  def __init__(self, size, max_moves, knight):
    self.size = size
    self.max_moves = max_moves
    self.knight = knight
    
  def solve(self, pos, steps=0):
    '''Returns a dict of tuple positions => moves away'''
    moves = {}
    
    if steps <= self.max_moves:
      moves[pos] = steps
      
    if steps < self.max_moves:
      for possible in self.KNIGHT_MOVES:
        delta = (pos[0] + possible[0], pos[1] + possible[1])
        # If the delta is in bounds
        if delta[0] >= 0 and delta[0] < self.size and \
          delta[1] >= 0 and delta[1] < self.size:
          # Get the sub moves from the possible move location
          sub_moves = self.solve(delta, steps + 1)
          # Merge
          for p, value in sub_moves.items():
            if p in moves and value < moves[p]:
              # New minimum value for location
              moves[p] = value
            elif p in moves and value >= moves[p]:
              pass # Do nothing
            else:
              # Insert anyway
              moves[p] = value
        
    return moves
    
  def print_board(self, pos_map):
    '''Prints a 'chess board' with the specified positions
       appearing as their set numbers, otherwise as a period.'''
    for y in range(self.size):
      print(' '.join([str(pos_map[(y, x)]) if (y, x) in pos_map else '.' for x in range(self.size)]))
  
size = int(input("Size: "))
max_moves = int(input("Moves: "))
knight = tuple(map(lambda x: int(x), input("Knight: ").split(",")))

solver = KnightSolver(size, max_moves, knight)
solver.print_board(solver.solve(solver.knight))
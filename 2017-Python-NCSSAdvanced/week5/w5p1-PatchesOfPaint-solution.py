class PatchCounter:
  DIRECTION_DELTAS = [(-1, -1), (0, -1), (1, -1),
                      (-1,  0),          (1,  0),
                      (-1,  1), (0,  1), (1,  1)]
  
  def __init__(self):
    self.spots = set() # Array of paint 'spots' in form of tupless
  
  def load_file(self, filename):
    with open(filename, 'r') as f:
      for y, l in enumerate(f.readlines()):
        for x, c in enumerate(l.rstrip()):
          if c == '%': # If the co-ordinate is a spot of paint
            self.spots.add((x, y)) # Append the positions to the list of spots
  
  def count_patches(self):
    count = 0
    spots = self.spots.copy()
    queue = []
    
    while spots: # While spots is not empty
      # Pop a spot and add it to the queue
      pos = spots.pop()
      queue.append(pos)
      # Append count by one
      count += 1
      while queue: # While the queue is not empty
        # For every direction
        for possible in [(pos[0] + delta[0], pos[1] + delta[1]) for delta in self.DIRECTION_DELTAS]:
          if possible in spots: # If the possible location is still in the list of available spots
            # Append it to the queue
            queue.append(possible)
            # And remove i from the spots
            spots.remove(possible)
        # Get the next position to work on
        pos = queue.pop()
    
    return count
  
pc = PatchCounter()
pc.load_file('patches.txt')

patches = pc.count_patches()
if patches == 1:
  print('1 patch')
else:
  print('%i patches' % patches)
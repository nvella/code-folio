class Maze:
  DIRECTION_DELTAS = [(0, -1), (-1, 0), (0, 1), (1, 0)]
  
  def __init__(self):
    self.size = (0, 0)
    # Arrays of co-ord tuples
    self.pacman  = (0, 0)
    self.walls   = []
    self.pacdots = []
    self.ghosts  = []
    
  def load_maze_str(self, maze_str):
    '''Load a maze from a string'''
    for y, line in enumerate(maze_str.split("\n")):
      for x, char in enumerate(line):
        if   char == '#':
          self.walls.append((x, y))
        elif char == '.':
          self.pacdots.append((x, y))
        elif char == 'G':
          self.ghosts.append((x, y))
        elif char == 'P':
          self.pacman = (x, y)
        
        # The last character processed will be on the last line, this is the size
        self.size = (x + 1, y + 1)
        
  def step(self):
    '''Step the maze (move all ghosts one step closer to Pacman)'''
    for i, ghost in enumerate(self.ghosts):
      path = self.pathfind(ghost, self.pacman)
      if path is not None:
        # If a path was found, move the ghost to the next step on that path
        self.ghosts[i] = path[1]
  
  def pathfind(self, a, b):
    '''Find the shortest path from a to b using BFS'''
    todo = [[a]] # Start with just position A 

    while todo: # While todo is not empty
      top = todo.pop(0)
      end = top[-1] # End of path
      
      if end == b:
        # If the path ends at the desty, return it
        return top
      
      # Check adjacent squares
      for check_pos in [(end[0] + delta[0], end[1] + delta[1]) for delta in self.DIRECTION_DELTAS]:
        if check_pos in self.walls:
          continue # Skip this possible direction if a wall is in our way
        if check_pos in top:
          continue # Skip this possible direction if it is already present in the path
        
        # Prepare this to proceed as a new path
        todo.append(top + [check_pos]) # Add this new path to the todo queue
              
  def __str__(self):
    '''Produce a string representation of the maze'''
    out = ''
    for y in range(self.size[1]):
      for x in range(self.size[0]):
        pos = (x, y)
        if pos == self.pacman:
          out += 'P'
        elif pos in self.walls:
          out += '#'
        elif pos in self.ghosts:
          out += 'G'
        elif pos in self.pacdots:
          out += '.'
        else:
          out += ' '
      out += '\n'
    return out.rstrip()
    
maze = Maze()
with open('maze.txt', 'r') as f:
  maze.load_maze_str(f.read())
maze.step()
print(maze)
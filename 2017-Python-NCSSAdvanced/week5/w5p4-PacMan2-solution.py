class Pacman:
  DIRECTION_DELTAS = [(0, -1), (-1, 0), (0, 1), (1, 0)]
  GAME_DIRECTIONS = {'U': (0, -1), 'D': (0, 1), 'L': (-1, 0), 'R': (1, 0)}
  
  def __init__(self):
    self.size = (0, 0)
    # Game variables
    self.points = 0
    self.dead = False
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
        
  def play(self, cmds):
    for cmd in cmds:
      if cmd == 'O':
        self.print_board()
        continue
        
      # Move pacman
      old_pacman = self.pacman
      # If cmd is a valid direction
      if cmd in self.GAME_DIRECTIONS:
        direction = self.GAME_DIRECTIONS[cmd]
        new_pos = (self.pacman[0] + direction[0], self.pacman[1] + direction[1])
        # If new position is and bounds and it is not a wall
        if self.pos_in_bounds(new_pos) and new_pos not in self.walls:
          self.pacman = new_pos
             
      # Check for game end
      if self.is_dead() or self.is_won():
        break
          
      # Eat pacdots
      if self.pacman in self.pacdots:
        self.points += 1
        self.pacdots.remove(self.pacman)
          
      # Check for game end
      if self.is_dead() or self.is_won():
        break

      # Step ghosts
      self.step_ghosts(old_pacman)
      
      # Check for game end
      if self.is_dead() or self.is_won():
        break
    
    self.print_board()
    
  def pos_in_bounds(self, pos):
    return pos[0] >= 0 and pos[0] < self.size[0] and pos[1] >= 0 and pos[1] < self.size[1]
        
  def step_ghosts(self, towards):
    '''Step the ghosts (move all ghosts one step closer to Pacman)'''
    for i, ghost in enumerate(self.ghosts):
      path = self.pathfind(ghost, towards)
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
 
  def is_dead(self):
    # If the game is not won and Pacman shares a position with a ghost
    return (not self.is_won()) and self.pacman in self.ghosts
  
  def is_won(self):
    return len(self.pacdots) == 0
        
  def print_board(self):
    print(self)
          
  def __str__(self):
    '''Produce a string representation of the maze'''
    out = ''
    if   self.is_won():
      out += 'You won!\n'
    elif self.is_dead():
      out += 'You died!\n'
    out += 'Points: %i\n' % self.points
    
    for y in range(self.size[1]):
      for x in range(self.size[0]):
        pos = (x, y)
        if pos == self.pacman:
          out += 'X' if self.is_dead() else 'P'
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
    
pm = Pacman()
with open('maze.txt', 'r') as f:
  pm.load_maze_str(f.read())
commands = input('Commands: ').rstrip().split()
pm.play(commands)
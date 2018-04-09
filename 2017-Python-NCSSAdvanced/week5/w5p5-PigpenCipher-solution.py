import math
from PIL import Image

# Get bounding boxes of image rows by searching for consecutive rows of blank pixels
# Get vertical glyph segments of rows by searching for consecutive columns of blank pixels
# Get bounding boxes of glyphs by searching for top pixel, bottom bixel, leftmost and
#  right most pixels in that box

class PigpenScanner:
  GLYPHS = {     
            # Box glyphs, no dot
            (False, False,  True, False, False,  True,  True,  True,  True): 'A',
            ( True, False,  True,  True, False,  True,  True,  True,  True): 'B',
            ( True, False, False,  True, False, False,  True,  True,  True): 'C',
            ( True,  True,  True, False, False,  True,  True,  True,  True): 'D',
            ( True,  True,  True,  True, False,  True,  True,  True,  True): 'E',
            ( True,  True,  True,  True, False, False,  True,  True,  True): 'F',
            ( True,  True,  True, False, False,  True, False, False,  True): 'G',
            ( True,  True,  True,  True, False,  True,  True, False,  True): 'H',
            ( True,  True,  True,  True, False,  False, True, False, False): 'I',
            
            # Box glyphs, dot
            (False, False,  True, False,  True,  True,  True,  True,  True): 'J',
            ( True, False,  True,  True,  True,  True,  True,  True,  True): 'K',
            ( True, False, False,  True,  True, False,  True,  True,  True): 'L',
            ( True,  True,  True, False,  True,  True,  True,  True,  True): 'M',
            ( True,  True,  True,  True,  True,  True,  True,  True,  True): 'N',
            ( True,  True,  True,  True,  True, False,  True,  True,  True): 'O',
            ( True,  True,  True, False,  True,  True, False, False,  True): 'P',
            ( True,  True,  True,  True,  True,  True,  True, False,  True): 'Q',
            ( True,  True,  True,  True,  True,  False, True, False, False): 'R',
            
            # Arrow glyphs, no dot
            ( True, False,  True, False, False, False, False,  True, False): 'S',
            (False, False,  True,  True, False, False, False, False,  True): 'U',
            (False,  True, False, False, False, False,  True, False,  True): 'V',
            ( True, False, False, False, False,  True,  True, False, False): 'T',
            
            # Arrow glyphs, dot
            ( True, False,  True, False,  True, False, False,  True, False): 'W',
            (False, False,  True,  True,  True, False, False, False,  True): 'Y',
            (False,  True, False, False,  True, False,  True, False,  True): 'Z',
            ( True, False, False, False,  True,  True,  True, False, False): 'X',
            
            # Space
            (False,  True, False,  True, False,  True, False,  True, False): ' '
            }
  
  def __init__(self, filename):
    self.img = Image.open(filename)
    # self.debug = self.img.convert('RGB')
    
  def scan(self):
    out = ''
    # Get horizontal slices
    h_slices = self.find_horizontal_slices()
    for h_slice in h_slices:
      # Get vertical slices of that horizontal slice
      v_slices = self.find_vertical_slices((0, h_slice[0], self.img.width, h_slice[1]))
      for v_slice in v_slices:
        # Further refine the vertical slice
        h_refine = self.find_horizontal_slices((v_slice[0], h_slice[0], v_slice[1], h_slice[1]))[0]
        # Create a bounding box
        bbox = (v_slice[0], h_refine[0], v_slice[1], h_refine[1])
        grid_sample = self.get_tuple_grid_sample(bbox)
        if grid_sample in self.GLYPHS:
          out += self.GLYPHS[grid_sample]
    # self.debug.show()
    return out

        
  def get_tuple_grid_sample(self, bbox):
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    sample_coords = ((bbox[0],                                  bbox[1]), 
                     (bbox[0] + math.floor(width / 2),          bbox[1]), 
                     (bbox[0] + math.floor(width / 2 * 2) - 1,  bbox[1]), 
                     
                     (bbox[0],                                  bbox[1] + math.floor(height / 2)), 
                     (bbox[0] + math.floor(width / 2),          bbox[1] + math.floor(height / 2)), 
                     (bbox[0] + math.floor(width / 2 * 2) - 1,  bbox[1] + math.floor(height / 2)), 
                     
                     (bbox[0],                                  bbox[1] + math.floor(height / 2 * 2) - 1), 
                     (bbox[0] + math.floor(width / 2),          bbox[1] + math.floor(height / 2 * 2) - 1), 
                     (bbox[0] + math.floor(width / 2 * 2) - 1,  bbox[1] + math.floor(height / 2 * 2) - 1))
    return tuple([self.img.getpixel(p) != 255 for p in sample_coords])
    
  # def sample_area(self, pos):
  #   '''Sample a 3x3 pixel area at pos and return True if there's one black pixel'''
  #   self.debug.putpixel(pos, (255, 0, 0))
  #   for x in range(pos[0] - 1, pos[0] + 2):
  #     for y in range(pos[1] - 1, pos[1] + 2):
  #       if x >= 0 and x < self.img.width and y >= 0 and y < self.img.height:
  #         if self.img.getpixel((x, y)) != 255:
  #           return True
  #   return False

  def find_horizontal_slices(self, region=None):
    '''Find the horizontal slices of the image; slices are separated by a variable
       amonunt of blank lines'''
    if region is None:
      region = (0, 0, self.img.width, self.img.height)
    slices = []
    current_slice = None
    in_slice = False
    for y in range(region[1], region[3]):
      for x in range(region[0], region[2]):
        if self.img.getpixel((x, y)) != 255:
          in_slice = True
          break
        in_slice = False
      if in_slice:
        if current_slice is None:
          current_slice = [y, y]
        current_slice[1] = y + 1
      else:
        if current_slice is not None:
          slices.append(tuple(current_slice))
          current_slice = None
    if current_slice is not None:
      slices.append(tuple(current_slice))
    return slices
    
  def find_vertical_slices(self, region=None):
    '''Find the vertical slices of the image; slices are separated by a variable
       amonunt of blank lines'''
    if region is None:
      region = (0, 0, self.img.width, self.img.height)
    slices = []
    current_slice = None
    in_slice = False
    for x in range(region[0], region[2]):
      for y in range(region[1], region[3]):
        if self.img.getpixel((x, y)) != 255:
          in_slice = True
          break
        in_slice = False
      if in_slice:
        if current_slice is None:
          current_slice = [x, x]
        current_slice[1] = x + 1
      else:
        if current_slice is not None:
          slices.append(tuple(current_slice))
          current_slice = None
    if current_slice is not None:
      slices.append(tuple(current_slice))
    return slices
  
  def region_is(self, region, c):
    for x in range(region[0], region[2]):
      for y in range(region[1], region[3]):
        if self.img.getpixel((x, y)) != c:
          return False
    return True
    
path = input('Enter path: ')
ps = PigpenScanner(path)
print(ps.scan())
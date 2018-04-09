import string
import math

class TextAnalysis:
  def __init__(self):
    self.files = {}
    self.index = []
    
  def do_analysis(self):
    # Load required files
    ta.load_index("texts.txt")
    ta.load_file("unknown.txt")
    normalised = self.get_normalised_len_counts()
    similarities = [(f, self.cosine_similarity(normalised[f], normalised['unknown.txt'])) for f in self.index]
    for f, out in sorted(similarities, key=lambda x: -x[1]):
      print(out, f)
    
  def cosine_similarity(self, a, b):
    prodsum = sum([a[i] * b[i] for i in range(len(a))])
    bottom = math.sqrt(sum([v ** 2 for v in a])) * math.sqrt(sum([v ** 2 for v in b]))
    return prodsum / bottom
  
  def get_normalised_len_counts(self):
    maximum = max([max(v) for k, v in self.files.items()])
    d = {}
    for k, v in self.files.items():
      d[k] = [v[i] if i in v else 0 for i in range(1, maximum + 1)]
    return d
  
  def load_index(self, filename):
    for f in open(filename, 'r'):
      self.load_file(f.rstrip())
      self.index.append(f.rstrip())
  
  def load_file(self, filename):
    len_count = {}
    
    for l in open(filename, 'r'):
      for word in l.rstrip().split():
        word = word.strip(string.punctuation)
        if len(word) not in len_count:
          len_count[len(word)] = 0
        len_count[len(word)] += 1        
    
    self.files[filename] = len_count
  
ta = TextAnalysis()
ta.do_analysis()

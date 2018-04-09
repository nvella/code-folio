# Implement the following Node class API.
# If you delete something important, this code is copied in specification.py

class Node:
  def __init__(self, prefix):
    """
    Creates a Node with the given string prefix.
    The root node will be given prefix ''.
    You will need to track:
    - the prefix
    - whether this prefix is also a complete word
    - child nodes
    """
    self.prefix = prefix
    self.word = False
    self.children = {} # dict of children; prefix => node
  
  def get_prefix(self):
    """
    Returns the string prefix for this node.
    """
    return self.prefix
  
  def get_children(self):
    """
    Returns a list of child Node objects, in any order.
    """
    return list(self.children.values())
  
  def is_word(self):
    """
    Returns True if this node prefix is also a complete word.
    """
    return self.word
  
  def add_word(self, word, subset=1):
    """
    Adds the complete word into the trie, causing child nodes to be created as needed.
    We will only call this method on the root node, e.g.
    >>> root = Node('')
    >>> root.add_word('cheese')
    """
    prefix = word[:subset]
    if prefix not in self.children:
      # Create a node if it doesn't exist
      self.children[prefix] = Node(prefix)
    
    if subset == len(word):
      # If we have crawled to the end of the word, set it's flag to True
      self.children[prefix].word = True 
    else:
      # Recurse down with the word, incrementing the subset
      self.children[prefix].add_word(word, subset + 1)
  
  def find(self, prefix):
    """
    Returns the node that matches the given prefix, or None if not found.
    We will only call this method on the root node, e.g.
    >>> root = Node('')
    >>> node = root.find('te')
    """
    # Searches all children for node
    # Returns None if no results found
    # Returns node if a matching result was found through #find
    # Returns self if prefix matches
    if self.prefix == prefix:
      return self
    
    for child in self.get_children():
      result = child.find(prefix)
      if result: 
        return result
      
    return None
  
  def words(self):
    """
    Returns a list of complete words that start with my prefix.
    The list should be in lexicographical order.
    """
    results = [self.prefix] if self.is_word() else []
    
    for child in self.get_children():
      if child.is_word():
        results.append(child.get_prefix())
      
      results += child.words()
    
    return list(sorted(set(results)))


if __name__ == '__main__':
  # Write your test code here. This code will not be run by the marker.

  # The first example in the question.
  root = Node('')
  for word in ['tea', 'ted', 'ten']:
    root.add_word(word)
  node = root.find('te')
  print(node.get_prefix())
  print(node.is_word())
  print(node.words())

  # The second example in the question.
  root = Node('')
  for word in ['inn', 'in', 'into', 'idle']:
    root.add_word(word)
  node = root.find('in')
  print(node.get_prefix())
  children = node.get_children()
  print(sorted([n.get_prefix() for n in children]))
  print(node.is_word())
  print(node.words())

  # The third example in the question.
  with open('the-man-from-snowy-river.txt') as f:
    words = f.read().split()
  root = Node('')
  for word in words:
    root.add_word(word)
  print(root.find('th').words())
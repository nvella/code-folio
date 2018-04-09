import sys
import csv

class Student:
  def __init__(self, dc, name, score, preferences):
    self.dc = dc
    self.name = name
    self.score = score
    self.preferences = preferences[:9] # Array of preferences in descending order.
                                       # Preference => (course code, bonus marks or 0.0)

  def get_prefs_effective(self):
    '''Returns preferences with the effective score'''
    return [(code, min(self.score + bonus, 99.95)) for code, bonus in self.preferences]
  
  def get_degrees(self):
    return list(sorted(
                       list(filter(lambda t: t[0].student_in_slots(self), [(self.dc.degrees[pref[0]], pref[1]) for pref in self.get_prefs_effective()])),
                       key=lambda t: (([p[0] for p in self.get_prefs_effective()].index(t[0].code) + 1), -t[1])))

  def __repr__(self):
    return 'Student(%s, %f, %s)' % (self.name, self.score, str(self.preferences))
  
  def get_csv_row(self):
    degrees = self.get_degrees() # TODO
    degree_code = degrees[0][0].code if len(degrees) > 0 else '-'
    return {
            'name': self.name,
            'score': '%.2f' % self.score,
            'offer': degree_code
            }

class Degree:
  def __init__(self, dc, code, name, institution, places):
    self.dc = dc
    self.code = code
    self.name = name
    self.institution = institution
    self.places = places
    self.requests = [] # Slots of students; tuples (student, effective_score)
    self.slots = []
    
  def place_student(self, student, effective_score):
    '''Place a student in the requests queue'''
    self.requests.append((student, effective_score))
    self.recalculate_slots()
    
  def remove_student(self, student):
    for o in self.requests.copy():
      if o[0] == student:
        self.requests.remove(o)
    self.recalculate_slots()
    
  def recalculate_slots(self):
    self.slots = list(sorted(self.requests, key=lambda x: (-x[1], x[0].name)))[:self.places]
  
  def get_requests_sorted(self):
    return list(sorted(self.requests, key=lambda x: (-x[1], x[0].name)))
  
  def get_vacancies(self):
    return len(self.slots) < self.places
  
  def student_in_slots(self, student):
    return len(list(filter(lambda s: s[0] == student, self.slots))) > 0
  
  def get_csv_row(self):
    '''Return a csv row dict'''
    return {
            'code': self.code,
            'name': self.name,
            'institution': self.institution,
            'cutoff': '%.2f' % min(list(map(lambda p: p[1], self.slots))) if len(self.requests) > 0 else '-',
            'offers': len(self.slots),
            'vacancies': 'Y' if self.get_vacancies() else 'N'
            }
  
  def __repr__(self):
    return 'Degree(%i, %s, %s, %i) => %s' % (self.code, self.name, self.institution, self.places, str(['%s:%.2f' % (r[0].name, r[1]) for r in self.get_requests_sorted()]))

class DegreeCalculator:
  def __init__(self, degreesfn, studentsfn):
    self.degreesfn = degreesfn
    self.studentsfn = studentsfn
    
    self.degrees = {}
    self.students = []
    
  def run(self):
    self.load() # Load all degrees and students
    
    for student in sorted(self.students, key=lambda x: x.name): # Begin processing students, sorted by name
      for code, effective_score in student.get_prefs_effective(): # For each of the student's preferences
        self.degrees[code].place_student(student, effective_score) # Place the student
        
    # Process until students settle
    actioned = True
    while actioned:
      actioned = False
      for student in sorted(self.students, key=lambda x: x.name):
        # Remove student from all degrees where student is not first
        degrees = student.get_degrees()
        if len(degrees) > 1:
          for degree, effective_score in degrees[1:]:
            degree.remove_student(student)
          actioned = True
      
    # Write output
    writer = csv.DictWriter(sys.stdout, fieldnames=('code,name,institution,cutoff,offers,vacancies'.split(',')))
    writer.writeheader()
    for code, degree in sorted(self.degrees.items(), key=lambda x: x[0]):
      writer.writerow(degree.get_csv_row())
    print()
    # Write output
    writer = csv.DictWriter(sys.stdout, fieldnames=('name,score,offer'.split(',')))
    writer.writeheader()
    for student in sorted(self.students, key=lambda x: (-x.score, x.name)):
      writer.writerow(student.get_csv_row())
    
  def load(self):
    degrees_tbl = self.load_csv(self.degreesfn)
    students_tbl = self.load_csv(self.studentsfn)

    # Create the degrees
    self.degrees = {}
    for r in degrees_tbl:
      self.degrees[r['code']] = Degree(self, r['code'], r['name'], r['institution'], int(r['places']))

    # Create the students
    self.students = []
    for r in students_tbl:
      prefs = [
               (pref.split('+')[0], float(pref.split('+')[1])) if '+' in pref else (pref, 0.0)
               for pref in r['preferences'].split(';')
              ]
      self.students.append(Student(self, r['name'], float(r['score']), prefs))
      
  def load_csv(self, fn):
    with open(fn) as f:
      reader = csv.DictReader(f)
      return [dict(line) for line in reader]
    
dc = DegreeCalculator('degrees.csv', 'students.csv')
dc.load()
dc.run()

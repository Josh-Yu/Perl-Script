#!/usr/bin/env python2.6
 
import sys
import re
import os
#DATA DUMPER DEBUGGER
#import pprint
#pp = pprint.PrettyPrinter(indent=4)


def readlines(filename):
    """Function reads file specified by passed in filename 
    and returns a 1 level list with all the lines in the file as elements.
    Note: 
    -new line characters has been striped out
    -lines starting with # will be ignored
    """

    outputList = []

    fh = open(filename, "r")
    #print 'Name of the file: ', fh.name
 
    for line in fh:
        if not re.match("^#", line.lstrip()): #lsrip for cases where "    #" start with whitespace
            line.rstrip('\n')
            outputList.append(line.strip())
        else:
            print "# detected, ignoring current line"
    fh.close()
    return outputList
 


def readtable(filename):
    """
    Function reads file specified by passed in filename and returns a list of lists.
    -\n has been striped
    -lines starting with # will be ignored
    """
    outerList = []

    innerList = readlines(filename)
    for element in innerList:
            line = element
            outerList.append(line.split(':')) #split returns list with elements via delimted values
    return outerList


def writelines(filename,lines):
    """
    Function will write to file specified by filename. The Function will write the data passed into the function as a list.
    Note: A temporary file will be created and if successful in writing to temp file, function will rename the temp file to 
    the specified filename passed into the function
    IF successful, function will return 1, ELSE return 0
    """
    #gives me the absolute file path currently then dirname the abso path
    directory = os.path.dirname(os.path.abspath(filename))
    #print "Directory of File name is: " + directory
    try:
        fh = open(directory + "/temp", "w+")

        for line in lines:
            line = str(line) #converts non-strings to strings eg numbers
            fh.write(line + "\n")
  
    except IOError:
        print "ERROR: IO ERROR Occurred "
        return 0

    else:
        fh.close()
       # print "Written file successfully to " + directory + "/temp"
        os.rename(directory + '/temp', filename)
        #print "Renamed the file to " + filename
        return 1



######## MAIN METHOD FOR TESTING MODULE FUNCTIONS ###########
#readlines('./data/SUBJECTS')
#readtable('./data/SUBJECTS')
#if writelines('yolo', [1,2,3,4,5, 'bob']):
 #print "TRUE 1 RETURNED"
#else:
  #print "FALSE 0 RETURNED"
######## END TESTING METHOD###########
 
 
########################################################################
#
#   Enrol Class (Base Class)
#
########################################################################
class Enrol:
    """
    Blueprint to create base Object
    Encapsulates the whole system.
    Contains dictionary to hold subject objects
    Checks if the directoy passed in the constructor is valid
    Contains the dictionary holding venue information and capacity, used for lookup purposes
    """
    def __init__(self,directoryPath):
        if not os.path.isdir(directoryPath):
            raise Exception("Error: " + directoryPath + " is not a valid directory")
            sys.exit
        self.directory = directoryPath
        self.subjectsContainer = self._createSubject()
        self.venueDictionary = self._createVenue()             #simple lookup dictionary key => venueName, value => capacity
        
        #print "Subjects in the system  are: "
        #pp.pprint(self.subjectsContainer)


#######################################################################
# USED TO CREATE DICTIONARY LOOK UP OF VENUES key=>room_number, Value=>capacity
# Function will read venue File and create a dictionary of key/value pair of key =room_number and value= capacity
# Function returns a dictionary
#######################################################################
    def _createVenue(self):
        """
        Function called by Enrol Constructor,
        Reads VENUES file and extracts the location and capacity and create a simple dictionary lookup
        with key=>venueLocation, value=>capacity
        """
        dictionary = {}
        #print "Inside _createVenue()"

        outerList = readtable(os.path.join(self.directory,"VENUES"))
        
        for item in outerList:               #iterating through the list from venues file
             dictionary[item[0]] = item[1]   #assigning the keys and values to the dictionary
        return dictionary
        

#######################################################################
# USED TO CREATE SUBJECT OBJECTS AND CREATE DICTIONARY
# This will call readtable() to read the subjects file and create and return a dictionary of the subjects 
# key will be the subject ID and the value will be the subject object
 #######################################################################
    def _createSubject(self):
        """
        Function called by Enrol Constructor,
        Reads SUBJECT file and creates subject object for each subject code in the file
        then add them to the Enrol objects subject dictionary
        """
        dictionary = {}
        #print "Inside create Subject"
        outerList = readtable(os.path.join(self.directory,"SUBJECTS"))

        for item in outerList:
            object = Subject(self.directory,item[0],item[1])
            dictionary[item[0]] = object
        return dictionary
 

#######################################################################
# Returns the subject codes in the system
#######################################################################
    def subjects(self):
        """
        Function returns a list of all the subject codes in the system
        """
        return self.subjectsContainer.keys()
#######################################################################
# Given a subject code, should return the subject name of it
#######################################################################
    def subjectName(self,subjectCode):
        """
        Function returns the string(subject Name) of the subjectCode Specified
        """
        if subjectCode in self.subjectsContainer:
            subjectObject = self.subjectsContainer[subjectCode]
            #print subjectObject.subjectName #^^^^^^^^^^^^
            return subjectObject.subjectName
        else:
            return None
#######################################################################

#######################################################################
    def classes(self, subjectCode):
        """
        Returns a list of classes for the subject code specified
        """
        #print "Inside Classes"
        #iterate through the dictionary of subjects and return the class list   
        #print "Printing" , self.subjectsContainer[subjectCode].classContainer.keys(),
        return self.subjectsContainer[subjectCode].classContainer.keys()

#######################################################################      
# ClassInfo, returns info about the class as a tuple 
#######################################################################       
    def classInfo(self, class_ID):  
        """
        Function searches for specified class_ID and 
        returns a tuple containining (subjectCode, date, venue, tutor Name, list of enrolled students for class)
        """
     #find the subject, find the specific class then fetch the tuple
        classObject = None
        for key in self.subjectsContainer:
            #print "****Current subject key is:" ,key,"|"
            subjectObject =  self.subjectsContainer[key]
            classObject = subjectObject._getClass(class_ID)
            if classObject != None:
                #print classObject._getClassInfo()
                return classObject._getClassInfo()
                break; #break out of loop if the classID is found
        if classObject == None:
            raise KeyError("Class ID cannot be found")

        

####################################################################### 
# checkStudent returns accepts 2 arguments (studentID, subjectCode) 
# StudentID is a mandatory argument, subjectCode is Optional
####################################################################### 
    def checkStudent(self, studentID, subjectCode = None):
        """
        Function accepts 2 arguments, StudentID is madatory and subjectCode is optional
        WHen student ID is only provided, Function returns a list of classes the student is enrolled in
        IF both arguments are provided, Function returns the (string)classID the student is enrolled in 
        for the subject code specified
        If a student cannot be found for the subject_code specified then return None
        """
        studentClassList = []

        if subjectCode == None:
            #print "User has not provided a subject code"
            for value in self.subjectsContainer.values(): #loop through each subjects,
                if value._findStudent(studentID) != None: #if the result returned from _findStudent is not none, append it to studentClassList
                    studentClassList.append(value._findStudent(studentID))
            return studentClassList

        else:      #student has provided a student code
            try:
                #print "Subject Code has been provided"
                return self.subjectsContainer[subjectCode]._findStudent(studentID)   

            except KeyError: #This exception is for cases when the subject ID is invalid, eg does not exist
                print "KeyError Occurred in checkStudent, Returning None"
                return None

        #print "CheckStudent END"
        #pp.pprint(studentClassList)

#######################################################################
#Enrol function will enrol student id into the class ID specified.
#######################################################################
    def enrol(self,studentID, class_ID):
        """
        Function used to enrol a studentID into a specific ClassID
        Additional checks are performed such as, if a student is already enrolled in another class of the same subject 
        then unenrol them and enrol them into the new classID specified.
        Class capacity checks are performed to determine if the new class has enough room for the new student
        IF enrol is accepted then return 1, ELSE return None
        """
        classStudentCount = None #this will hold the current count of enrolled student in a class
        try:
            classTuple = self.classInfo(class_ID)
            classSubject,classLocation, classStudentList = classTuple[0],classTuple[2],classTuple[4] #returns a list of students in enrolled in the class
            classStudentCount = len(classStudentList) #Counting the number(length) of the list from the tuple -> classStudentList)

            #print "Class  Location" ,classLocation, ""
            #print "classCount BEFORE IF" ,classStudentCount, ""
        except KeyError:
            print "Cannot Enrol Student, class ID does not exist"
            raise KeyError


        #check if venue(class location exist in the system)
        if classLocation in self.venueDictionary:
            #important to convert the str from dictionary to an int to do comparsion 
            venueCapacity = int(self.venueDictionary[classLocation])
            if classStudentCount < venueCapacity:
                
                subjectObject =  self.subjectsContainer[classSubject]
                classObject = subjectObject._getClass(class_ID)

                subjectObject._removeStudentDuplicate(studentID)

                classObject._addStudent(studentID)
                return 1
            else:
                print "Capacity of the class you would like to enrol into is not enough"
                return None
        else:
            print "Class Location does not exist in the system, Venues file does not contain the location"
            return None



########################################################################
#
#   Subject CLASS
# A subject can have multiple classes which is stored in classContainer
# The subject object creates classes objects using _createClass
########################################################################
class Subject:
    """
    Blueprint to create subject object.
    The object will encapsulate the information related to the subject
    Including a dictionary of classes the subject is associated with
    """
    def __init__(self,directory,subjectCode,subjectName):
        self.directory = directory
        self.subjectCode = subjectCode
        self.subjectName = subjectName
        self.classContainer = {} #CONTAINS ALL THE CLASSES ASSSOCIATED WITH THE COURSE, Key => CLASS_ID, VALUE => CLASS_OBJECT
        self.classContainer = self._createClass(self.subjectCode)
        
       # print "====Dealing with object",subjectCode ,subjectName,
       # pp.pprint(self.classContainer)


#######################################################################
# Function will read the CLASSES FILE and create the class object for 
# the particular subject_Code passed in then add them to a internal dictionary
# which is return to the constructor of Subject
#######################################################################
    def _createClass(self,subjectCode):
        """
        Function called by the Subject constructor.
        Function reads the classes file and creates the classes that matches the subject of the current subject object
        """
        #print "Inside _createClass"
        dictionary = {}
        outerList = readtable(os.path.join(self.directory,"CLASSES"))
    
        for item in outerList:
            if item[1] == self.subjectCode:
                object = Class(self.directory,item[0],item[1],item[2],item[3],item[4]) #creating the class object inline
                dictionary[item[0]] = object                         #key=>bw101.1, value =>classObject
       # print "Exiting method _createClass in class Subject"
        return dictionary
#######################################################################


#######################################################################   
# Function will look inside each class inside the dictionary/Container and call
# _studentExists on the object, if found it will return the classID

# Assume the student can only exist once in classes per subject

# Go through all the classes in the dictionary of this object and check if the student ID exist in those classes. If found, save the class ID then break out of loop. 
# At the END of ITERATION OR break return the classID found.
# if not found, default returns none 
#######################################################################
    def _findStudent(self,studentID): 
        """
        Function will search every individual class for the current subject and check which class the student is enrolled in.
        
        The function internally calls _studentExists which returns the classID if the studentID is found,
        ELSE returns None if no match        
        """
        foundStudent = None
        classID = None
        #print "========== INSIDE _FINDSTUDENTS()========="
        for key, value in self.classContainer.iteritems():
            #print "Current key is " + key
            if value._studentExist(studentID):
                classID = key
                foundStudent = True
                break;
            else:
                foundStudent = False
                #print "Found student = false"

        if foundStudent == True:
            #print "FOUND STUDENT IN CLASS" ,classID, ""
            return classID
        else:
            #print "NOT FOUND IN CLASS", classID , "RETURNING None"
            return None
        
#######################################################################  
# HELPER FUNCTION - Find class inside subject and return it(object) if found.
# Function will check if the classID is in "classContainer" dictionary inside Subject object, 
# if found, returns the class object, else should return NONE
# Function is called by classInfo(self, class_ID):
####################################################################### 
    def _getClass(self, classID):
        """
        Function will search the classes dictionary in the subject object
        looking for a matching classID. Returns the class(object) if found,
        Else returns None if class does not exist in the subject object
        """
        #print "_getClass, trying to find ",classID, "|"
        if classID in self.classContainer:
            #print "Found class ",classID, " inside subject object ",self.subjectCode, "|"
            return self.classContainer[classID]
        else:
            return None 
            
            
#######################################################################
#used to check and remove student ID's that are enrolled in other classes in the same subject
#used by Enrol
#loop through each class and check if the studentID exist, if so then call the classes removestudent() method
#######################################################################
    def _removeStudentDuplicate(self, studentID):
        """
        Function will check if the studentID exists in any other classes in the current subject
        If the student is enrolled/exist in another class in the same subject then remove that student
        from class by calling the _removeStudent function on that class
        """
        for eachClass in self.classContainer.values():
            if eachClass._studentExist(studentID) == True:
                eachClass._removeStudent(studentID)

########################################################################
#
#   Classes object(blueprint for each individual class in the system)
#
########################################################################
class Class:
    """
    Blueprint to create an individual class object.
    The object will encapsulate the information related to the class
    Including a list of enrolled students which is read from the roll file
    """
    def __init__(self,directory,class_ID,subjectCode,date,venue,tutor):
        self.directory = directory
        self.class_ID = class_ID
        self.subjectCode = subjectCode
        self.date = date
        self.venue = venue
        self.tutor = tutor
        self.studentEnrolled = [] #initialise empty student roll in the class
        self.rollFile = os.path.join(self.class_ID + ".roll") 
        self._popululateClass()
        #print "<<<<<Class: " + self.class_ID + " Enrolled students>>>>>>"
        #pp.pprint(self.studentEnrolled)

#######################################################################
# Function will return a tuple of the current class object containing 
# (subject_code, time, room, tutor, list of students)
#######################################################################
    def _getClassInfo(self):
        """
        Function returns a tuple of the current class
        consisting of (subject_code, date, venue, tutor, list of enrolled students)
        """
        classTuple = (self.subjectCode,self.date,self.venue,self.tutor,self.studentEnrolled)
        return classTuple
    
#######################################################################
# Find the roll file for this class, reads the student numbers into the list
#######################################################################
    def _popululateClass(self):
        """
        Function is used to populate the studentEnrolled list with studentID's
        by reading the roll file associated with the classes object.
        """
        #This will read the file and append the information in a 1 level list 
        # INSTEAD of a list of lists eg [[student_Number]]
        try:
            for item in readtable(os.path.join(self.directory,self.rollFile)):
                for innerElement in item:
                    self.studentEnrolled.append(innerElement[:])
        except IOError:
            print "RollFile " + self.rollFile + " Not Found"
    

#######################################################################
# HELPER FUNCTION - check if student exist in the individual class object
# Function will search studentEnrolled List and 
# return True if the student exist in this class, 
# else return False
# 
#######################################################################
    def _studentExist(self, studentID):
        """
        Function searches the class to determine if a student is enrolled in it or not
        returns true if a studentID exists the classes object studentEnrolled List
        IF studentID does not exist, returns False
        """
        if studentID in self.studentEnrolled:
            #print "Student found in studentEnrolled"
            return True
        else:
            return False


############  For Enrol    Functionality ###########################

    #Adds the student ID to the list of enrolled students in the class
    # Used for enrolling students
    def _addStudent(self, studentID):
        """
        Function will add the passed in studentID to the list of enrolled students for this classes object
        Once added/appended to the list. The whole list is written to the roll file associated with the class
        """
        self.studentEnrolled.append(studentID)
        #print "Successfully added student: " ,studentID, "to class: " ,self.class_ID , "|"
        writelines(os.path.join(self.directory,self.rollFile),self.studentEnrolled)

    #used to remove the individual student from the class Roll for this classes object
    def _removeStudent(self, studentID):
        """
        Function removes the studentID passed in, from the list of enrolled students for this classes object
        Also, once removed. The function will write the changes to the roll file associated with the class
        """
        self.studentEnrolled = [x for x in self.studentEnrolled if x != studentID]
        writelines(os.path.join(self.directory,self.rollFile),self.studentEnrolled)

#checks whether the enrol.py file has been executed directly
if __name__ == "__main__":
    print("enrol.py should not be run directly")

######TESTING OOP(main) #################################################################

#object = Enrol("./data") #creating a new object and passing the parameter of the directory

#object.subjects()
#object.subjectName('bw101')


#object.classes('bw101') #Subject ID is valid
#object.classes('11101') #subject ID is invalid


#object.classInfo('bw101.') #class ID does not exist


#object.enrol('1122345','bw101.1')
#object.classInfo('bw101.1') #class ID does  exist



#NEGATIVE
#object.checkStudent('9999', 'bw1012') # studentId is invalid, Subject ID is invalid
#object.checkStudent('1124395', 'bw1012') #student ID is valid, subject ID is invalid
#object.checkStudent('1124395', 'bw23') #student ID is valid, subject code invalid
#object.checkStudent('112', 'bw101') #student ID is invalid, subject code valid

#POSITIVE
#object.checkStudent('1124395', 'bw101') #student ID is valid and subject ID is valid

#object.checkStudent('1112345')
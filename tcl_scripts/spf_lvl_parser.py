import os
import shutil
from queue import PriorityQueue

class Coordinate():
    def __init__(self, x = 0, y = 0):
        self.x = x
        self.y = y

    def __str__(self):
        return f'Coord : {self.x}, {self.y}'

class SPF():
    def __init__(self):
        self.Nets    = []
        self.pinDict = {}
        self.connect = PriorityQueue()

    def insertNet(self, Net):
        self.Nets.append(Net)
        for name, pin in Net.pinDict.items():
            self.pinDict[name] = pin

        for conn in Net.connect:
            self.connect.put(conn)

    def __str__(self):
        str = ''
        printqueue = self.connect
        while not printqueue.empty():
            item = printqueue.get()
            str += item.__str__()
            str += '\n'

        return str


class Net():
    def __init__(self, netName = '', netCap = 0):
        self.netName  = netName
        self.netCap   = netCap
        self.pin      = 0
        self.instPins = PriorityQueue()
        self.subNodes = PriorityQueue()
        self.caps     = []
        self.ress     = []
        self.connect  = []
        self.pinDict  = {}
        
    def insertPin(self, pin):
        self.pin = pin
        self.pinDict[pin.name] = pin

    def insertInstPin(self, instPin):
        self.instPins.put(instPin.lvl, instPin)
        self.pinDict[instPin.name] = instPin
    
    def insertSubNode(self, subNode):
        self.subNodes.put(subNode.lvl, subNode)
        self.pinDict[subNode.name] = subNode
    
    def insertCap(self, cap):
        self.caps.append(cap)

    def insertRes(self, res):
        self.ress.append(res)
        p1 = self.pinDict[res.instPinNameS]
        p2 = self.pinDict[res.instPinNameD]
        lvl_p1 = p1.lvl
        lvl_p2 = p2.lvl

        conn = Conn(p1, p2) if lvl_p1 < lvl_p2 else Conn(p2, p1)
        self.connect.append(conn)

    def __str__(self):
        return f''


class Pin():
    def __init__(self, words):
        self.name    = words[1][1:]
        self.pinType = words[2]
        self.pinCap  = float(words[3])
        self.Coord   = Coordinate(float(words[4]), float(words[5][:-1]))
        self.llx     = float(words[7][5:])
        self.lly     = float(words[8][5:])
        self.urx     = float(words[9][5:])
        self.ury     = float(words[10][5:])
        self.lvl     = int(words[11][5:])
    
    def __str__(self):
        return f'Pin : {self.name} in {self.lvl}'


class InstPin():
    def __init__(self, words):
        self.name     = words[1][1:]
        self.instName = words[2]
        self.pinName  = words[3]
        self.pinType  = words[4]
        self.pinCap   = float(words[5])
        self.Coord    = Coordinate(float(words[6]), float(words[7][:-1]))
        self.llx      = float(words[9][5:])
        self.lly      = float(words[10][5:])
        self.urx      = float(words[11][5:])
        self.ury      = float(words[12][5:])
        self.lvl      = int(words[13][5:])

    def __str__(self):
        return f'InstPin : {self.name} in {self.lvl}'


class SubNode():
    def __init__(self, words):
        self.name  = words[1][1:]
        self.Coord = Coordinate(float(words[2]), float(words[3][:-1]))
        self.llx   = float(words[5][5:])
        self.lly   = float(words[6][5:])
        self.urx   = float(words[7][5:])
        self.ury   = float(words[8][5:])
        self.lvl   = int(words[9][5:])

    def __str__(self):
        return f'SubNode : {self.name} in {self.lvl}'


class Cap():
    def __init__(self, words):
        self.capName      = words[0]
        self.instPinNameS = words[1]
        self.instPinNameD = words[2]
        self.cvalue       = float(words[3])


class Res():
    def __init__(self, words):
        self.resName      = words[0]
        self.instPinNameS = words[1]
        self.instPinNameD = words[2]
        self.rvalue       = float(words[3])


class Conn():
    def __init__(self, pinS, pinD):
        self.pinS = pinS
        self.pinD = pinD
    
    def __str__(self):
        return f'lvl {self.pinS.lvl} to {self.pinD.lvl} : {self.pinS.name} to {self.pinD.name}. {self.pinS.Coord.__str__()} to {self.pinD.Coord.__str__()}'

    def __lt__(self, other):
        if self.pinS.lvl != other.pinS.lvl:
            return self.pinS.lvl < other.pinS.lvl
        else:
            return self.pinD.lvl < other.pinD.lvl
    
    def __eq__(self, other):
        return (self.pinS.lvl == other.pinS.lvl) and (self.pinD.lvl== other.pinD.lvl)


def parser(name):
    infile = open(name, 'r')
    lines = infile.readlines()
    infile.close()

    spf = SPF()
    net = Net()
    toggle = False

    for line in lines:
        if '*|NET' in line:
            if toggle == True:
                spf.insertNet(net)
            net = Net()
            words = line.split()
            net = Net(words[1], float(words[2][:-2]))
            toggle = True
            continue

        if '*|P' in line:
            words = line.split()
            if words[0] == '*|P':
                pin = Pin(words)
                net.insertPin(pin)
        
        if '*|I' in line:
            words = line.split()
            instPin = InstPin(words)
            net.insertInstPin(instPin)

        if '*|S' in line:
            words = line.split()
            subNode = SubNode(words)
            net.insertSubNode(subNode)

        if 'C' == line[0]:
            words = line.split()
            cap = Cap(words)
            net.insertCap(cap)

        if 'R' == line[0]:
            words = line.split()
            res = Res(words)
            net.insertRes(res)
    
    print(spf)

if __name__ == '__main__':
    path = '../spf/'
    name = 'usb_phy_test_reduction_yes_comments.spf'

    parser(path+name)



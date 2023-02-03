import subprocess
import os
import csv
import matplotlib.pyplot as plt
import numpy as np
import math

def subprocess_open(command):
    popen = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    (stdoutdata, stderrdata) = popen.communicate()
    return stdoutdata

def resultLoader_(bench):
    data = subprocess_open(f'cat result/SYN_REP/{bench}/*/summary.rpt')
    data = data.decode('utf-8')
    data = data.split('\n')
    return data

# csv format; 0:lvt, 1:rvt, 2:clock, 3:vdd, 4:track, 5:AREA, 6:WNS, 7:DYN_PWR, 8:LEAK
def summary2CSV(bench):
    try:
        f = open(f'./result_SYN/{bench}/result.csv','w', newline='')
        wr = csv.writer(f)
        wr.writerow(['lvt', 'rvt', 'clock', 'vdd', 'track', 'AREA', 'WNS', 'DYN_PWR', 'LEAK'])
        inDirs = os.listdir(f'./result/SYN_REP/{bench}/')
        for inDir in inDirs:
            # print(inDir)
            params = inDir.split('_')
            lvt = f'{params[2]}.{params[3]}'
            rvt = f'{params[5]}.{params[6]}'
            clock = f'{params[8]}'
            vdd = f'{params[10]}.{params[11]}'
            if params[13][0] == '6':
                track = 6
            else:
                track = 7.5

            rpt = open(f'./result/SYN_REP/{bench}/{inDir}/summary.rpt','r')
            data = rpt.readline()
            AREA, WNS, DYN_PWR, LEAK = data.split(',')
            wr.writerow([lvt, rvt, clock, vdd, track, AREA, WNS, DYN_PWR, LEAK])
        f.close()
        return f'{bench} success'

    except:
        return f'{bench} failed'

def csv2Plot(bench):
    try:
        path = f'./result_SYN/{bench}/'
        f = open(path+'result.csv','r')
        rdr = csv.reader(f)
        lvts = []
        rvts = []
        clocks = []
        vdds = []
        tracks = []        
        AREAs = []
        WNSs = []
        DYN_PWRs = []
        LEAKs = []
        next(rdr)
        for line in rdr:            
            lvts.append(float(line[0]))
            rvts.append(float(line[1]))
            clocks.append(float(line[2]))
            vdds.append(float(line[3]))
            tracks.append(float(line[4]))
            AREAs.append(float(line[5]))
            WNSs.append(float(line[6]))
            DYN_PWRs.append(math.log10(float(line[7])))
            LEAKs.append(math.log10(float(line[8])))
        
        # lvt, rvt - AREA
        drawScatter(lvts, rvts, AREAs, 'lvt', 'rvt', 'AREA', path, 'lvt_rvt_area')
        drawScatter(lvts, rvts, WNSs, 'lvt', 'rvt', 'WNS', path, 'lvt_rvt_WNS')
        drawScatter(lvts, rvts, DYN_PWRs, 'lvt', 'rvt', 'log DYN_PWR', path, 'lvt_rvt_DYN_PWR')
        return f'{bench} plot success'

    except:
        return f'{bench} plot failed'

def csv2Plot2(benches):
    try:
        lvts = []
        rvts = []
        clocks = []
        vdds = []
        tracks = []        
        AREAs = []
        WNSs = []
        DYN_PWRs = []
        LEAKs = []
        x = []
        i = 0
        for bench in benches:
            path = f'./result_SYN/{bench}/'
            f = open(path+'result.csv','r')
            rdr = csv.reader(f)            
            next(rdr)
            for line in rdr:
                lvts.append(float(line[0]))
                rvts.append(float(line[1]))
                clocks.append(float(line[2]))
                vdds.append(float(line[3]))
                tracks.append(float(line[4]))
                AREAs.append(float(line[5]))
                WNSs.append(float(line[6]))
                DYN_PWRs.append(math.log10(float(line[7])))
                LEAKs.append(math.log10(float(line[8])))
                x.append(i)
                i = i+1
            
        # lvt, rvt - AREA
        drawScatter(lvts, WNSs, DYN_PWRs, 'lvt', 'WNS', 'log DYN_PWR', f'./result_SYN/total', 'lvt_WNS_DYN_PWR')
        drawScatter(lvts, DYN_PWRs, WNSs, 'lvt', 'log DYN_PWR', 'WNS', f'./result_SYN/total', 'lvt_DYN_PWR_WNS')
        drawScatter(lvts, vdds, DYN_PWRs, 'lvt', 'vdd', 'log DYN_PWR', f'./result_SYN/total', 'lvt_vdd_DYN_PWR')
        drawScatter(vdds, DYN_PWRs, lvts, 'vdd', 'log DYN_PWR', 'lvt', f'./result_SYN/total', 'vdd_DYN_PWR_lvt')
        drawScatter(AREAs, WNSs, DYN_PWRs, 'area', 'WNS', 'log DYN_PWR',f'./result_SYN/total', 'AREA_WNS_DYN_PWR')
        drawScatter(AREAs, DYN_PWRs, LEAKs, 'area', 'log DYN_PWR', 'log LEAK', f'./result_SYN/total', 'AREA_DYN_PWR_LEAK')
        drawScatter(AREAs, lvts, tracks, 'area', 'lvt', 'track', f'./result_SYN/total', 'AREA_lvt_track')
        drawScatter(AREAs, DYN_PWRs, tracks, 'area', 'log DYN_PWR', 'track', f'./result_SYN/total', 'AREA_DYN_PWR_track')
        drawScatter(WNSs, DYN_PWRs, lvts, 'WNS', 'log DYN_PWR', 'lvt', f'./result_SYN/total', 'WNS_DYN_PWR_lvt')
        drawScatter(tracks, lvts, DYN_PWRs, 'track', 'lvt', 'log DYN_PWR', f'./result_SYN/total', 'track_lvt_DYN_PWR')
        drawScatter(tracks, DYN_PWRs, lvts, 'track', 'log DYN_PWR', 'lvt', f'./result_SYN/total', 'track_DYN_PWR_lvt')
        drawScatter(DYN_PWRs, lvts, tracks, 'log DYN_PWR', 'lvt', 'track', f'./result_SYN/total', 'DYN_PWR_lvt_track')
        drawScatter(x, AREAs, tracks, 'case', 'AREA', 'track', f'./result_SYN/total', 'AREA')
        drawScatter(x, WNSs, tracks, 'case', 'WNS', 'track', f'./result_SYN/total', 'WNS')
        drawScatter(x, DYN_PWRs, tracks, 'case', 'DYN_PWR', 'track', f'./result_SYN/total', 'DYN_PWR')
        drawScatter(x, LEAKs, tracks, 'case', 'LEAK', 'track', f'./result_SYN/total', 'LEAK')
        return f'plot success'

    except:
        return f'plot failed'

def drawScatter(x1, x2, y, x1_label, x2_label, y_label, path, name):
    plt.clf()
    plt.scatter(x = x1, y=x2, data=y, c=y, vmin=np.min(y), vmax = np.max(y), cmap='rainbow')
    plt.colorbar();
    plt.xlabel(x1_label)
    plt.ylabel(x2_label)
    plt.title(y_label)
    plt.savefig(f'{path}/{name}.png')

def main():
    benches = ['aes_cipher_top', 'des3']
    for bench in benches:
        print(summary2CSV(bench))
        print(csv2Plot(bench))
    print(csv2Plot2(benches))


if __name__ == "__main__":
    main()
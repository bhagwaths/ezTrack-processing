import os
import holoviews as hv
import numpy as np
import pandas as pd
import FreezeAnalysis_Functions as fz
import cv2

def list_paths(group, stages):
    sheet_list = []
    output_folders = []
    for i in range(len(stages)):
        sheet_path = rf'E:\{group}\{stages[i]}\{group}_{stages[i]}_info.csv'
        sheet_list.append(sheet_path)
        output_folder_path = rf'E:\{group}\{stages[i]}\FreezingOutput'
        output_folders.append(output_folder_path)
    return sheet_list, output_folders

def generate_output_files_2(sheet_list, output_folders, FPS):
    for sheet in range(len(sheet_list)):
        group_info = pd.read_csv(sheet_list[sheet])
        OutputFolder = output_folders[sheet]

        animalNames = group_info['animalNames']

        start_frames = []
        if 'video_light' not in group_info.columns:
            start_time = group_info['start_time'] # start times (mm:ss) of baseline included in sheet - for VideoFreeze, which has no light
            for time in start_time:
                time_list = time.split(':')
                if len(time_list) == 3:
                    hr, min, sec = time_list
                    secs = int(hr)*3600 + int(min)*60 + int(sec)
                else:
                    min, sec = time_list
                    secs = int(min)*60 + int(sec)
                frames = secs * FPS
                start_frames.append(frames)
        else:
            video_light = group_info['video_light'] # time (mm:ss) when light first turns on, marking end of baseline - for USB, which has light
            for time in video_light:
                time_list = time.split(':')
                if len(time_list) == 3:
                    hr, min, sec = time_list
                    secs = int(hr)*3600 + int(min)*60 + int(sec)
                else:
                    min, sec = time_list
                    secs = int(min)*60 + int(sec)
                frames = secs * FPS
                start_frame = frames - 180*FPS
                start_frames.append(start_frame)


        mt_cutoff = group_info['mt_cutoff']
        freeze_threshold = group_info['freeze_threshold']
        min_duration = group_info['min_duration']
        video_path = group_info['video_path']
        video_folder = group_info['video_folder']

        end_frames = []
        for video in video_path:
            cap = cv2.VideoCapture(video)
            num_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            if 'video_light' not in group_info.columns:
                num_frames /= 2
            end_frames.append(num_frames)

        for i in range(len(animalNames)):
            video_dict = {
                'dpath'   : video_folder[i],
                'file'    : video_path[i],
                'fpath'   : video_path[i],
                'start'   : start_frames[i], 
                'end'     : end_frames[i],
                'dsmpl'   : 1,
                'stretch' : dict(width=1, height=1)
            }
            print(video_dict['file'])
            print(end_frames[i])
            img_crp, video_dict = fz.LoadAndCrop(video_dict, cropmethod="Box")
            Motion = fz.Measure_Motion(video_dict, mt_cutoff[i], SIGMA=1) 
            FreezeThresh = freeze_threshold[i]
            MinDuration = min_duration[i]
            Freezing = fz.Measure_Freezing(Motion,FreezeThresh,MinDuration)
            fz.SaveData_custom(video_dict,Motion,Freezing,mt_cutoff[i],FreezeThresh,MinDuration,OutputFolder,animalNames[i])
    
def generate_blockpaths(group, stage):
    file = rf'E:\{group}\{stage}\{group}_{stage}_info.csv'
    print(file)
    group_info = pd.read_csv(file)
    data_paths = group_info['data_path']
    print('{', end="")
    for path in data_paths[:-1]:
        print("'" + path + "';")
    last_element = data_paths[len(data_paths)-1]
    print("'" + last_element + "'};")

def generate_animal_names(group, start, end, excl):
    num_list = list(range(start,end+1))
    num_list = [x for x in num_list if x not in excl]
    print('{', end="")
    for animal in num_list[:-1]:
        print("'" + group + '-' + str(animal) + "';")
    last_element = num_list[len(num_list)-1]
    print("'" + group + '-' + str(last_element) + "'};")

def generate_animal_names_excel(group, stage):
    file = rf'E:\{group}\{stage}\{group}_{stage}_info.csv'
    print(file)
    group_info = pd.read_csv(file)
    animal_names = group_info['animalNames']
    print('{', end="")
    for path in animal_names[:-1]:
        print("'" + path + "';")
    last_element = animal_names[len(animal_names)-1]
    print("'" + last_element + "'};")
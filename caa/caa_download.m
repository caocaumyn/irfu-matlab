function download_status=caa_download(tint,dataset,flags)
% CAA_DOWNLOAD Download CAA data in CDF format
%       CAA_DOWNLOAD - check the status of jobs in current directory
%
%       CAA_DOWNLOAD(tint,dataset) - download datasets matching 'dataset'
%
%       CAA_DOWNLOAD(tint,dataset,'nowildcard') - downloads dataset exactly matching 'dataset'
%
%       CAA_DOWNLOAD(tint,'list') - list all datasets available
%       CAA_DOWNLOAD(tint,'list:dataset') - only list all datasets matching 'dataset'
%
%       download_status=CAA_DOWNLOAD(tint,dataset) - returns 1 if sucessfull download 
%             returns 0 if request is put in the queue, 
%             the information of queued requests is saved in file ".caa"
%
%       CAA_DOWNLOAD(url_string) - download CAA data zip file from the link "url_string"
%
% Downloads CAA data in CDF format into subdirectory "CAA/"
%
%   tint   - time interval in epoch  [tint_start tint_stop]
%            or in ISO format, ex. '2005-01-01T05:00:00.000Z/2005-01-01T05:10:00.000Z'
%  dataset - dataset name, can uses also wildcard * (? is changed to *)
%
%  Examples:
%   caa_download(tint,'list:*')       % list everything available from all sc
%   caa_download(tint,'list:*FGM*')
%   caa_download('2005-01-01T05:00:00.000Z/2005-01-01T05:10:00.000Z','list:*FGM*')
%   caa_download(tint,'C3_CP_FGM_5VPS')
%   caa_download(tint,'C?_CP_FGM_5VPS')   %    download all satellites
%
% The example list of datasets: (see also http://bit.ly/pKWVKh)
% FGM
%   caa_download(tint,'C?_CP_FGM_5VPS');
%   caa_download(tint,'C?_CP_FGM_FULL');
% EFW (L2 - full resolution, L3 - spin resolution)
%   caa_download(tint,'C?_CP_EFW_L?_E3D_INERT'); % Ex,Ey,Ez in ISR2
%   caa_download(tint,'C?_CP_EFW_L?_E3D_GSE'); % Ex,Ey,Ez in GSE
%   caa_download(tint,'C?_CP_EFW_L?_E'); % Ex,Ey in ISR2
%   caa_download(tint,'C?_CP_EFW_L?_P'); % satellite potential
%   caa_download(tint,'C?_CP_EFW_L?_V3D_GSE'); % ExB velocity GSE
%   caa_download(tint,'C?_CP_EFW_L?_V3D_INERT'); % ExB velocity ISR2
% STAFF
%   caa_download(tint,'C?_CP_STA_PSD');
%   caa_download(tint,'*STA_SM*');           % STAFF spectral matrix
% WHISPER
%   caa_download(tint,'C?_CP_WHI_NATURAL');
% CIS
%   caa_download(tint,'C?_CP_CIS_HIA_ONBOARD_MOMENTS');
%   caa_download(tint,'C?_CP_CIS_CODIF_HS_H1_MOMENTS');
%   caa_download(tint,'C?_CP_CIS_HIA_HS_1D_PEF');
%   caa_download(tint,'C?_CP_CIS_CODIF_H1_1D_PEF');
% PEACE
%   caa_download(tint,'C?_CP_PEA_PITCH_SPIN_DPFlux'); % DPFlux/DEFLux/PSD
%   caa_download(tint,'C?_CP_PEA_3DR?_PSD');
%   caa_download(tint,'C?_CP_PEA_MOMENTS')
% RAPID
%   caa_download(tint,'C?_CP_RAP_ESPCT6'); % electron omni-directional
%   caa_download(tint,'C?_CP_RAP_L3DD');   % electron, 3D distribution (standard)
%   caa_download(tint,'C?_CP_RAP_E3DD');   % electron, 3D distr. (best) in BM
%   caa_download(tint,'C?_CP_RAP_HSPCT');  % ion, omni-directional
% EPHEMERIS
%   caa_download(tint,'C?_CP_AUX_POSGSE_1M');  % position & velocity for each sc
%   caa_download(tint,'CL_SP_AUX');            % position,attitude.. for all sc
%   caa_download(tint,'C?_CP_AUX_SPIN_TIME');  % spin period, sun pulse time,..
%   caa_download(tint,'C?_JP_PMP');            % invariant latitude, MLT, L shell.

% input 'flags' is in test phase
%   'test' - use caa test server instead
%   'nowildcard' - download the dataset without any expansion in the name and not checking if data are there
%   'overwrite' - overwrite files in directory (to keep single cdf file) NEEDS IMPLEMENTATION
%                 maybe this behavikour should be default
% $Id$

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

if exist('.caa','file') == 0, caa=cell(0);save -mat .caa caa;end
load -mat .caa caa
% caa.url - links to download
% caa.dataset - dataset to download
% caa.tintiso - time interval
% caa.zip - zip files to download
% caa.status - status ('submitted','downloaded','finnished')
% caa.timeofrequest - in matlab time units

flag_check_status_of_downloads=0; 

if nargin==0, flag_check_status_of_downloads=1; end
if nargin==1, % check if argument is not caa zip file link
    if ischar(tint) && strcmp(tint(end-2:end),'zip')
        j=numel(caa)+1;
        caa{j}.url='*';
        caa{j}.dataset='*';
        caa{j}.tintiso='*';
        caa{j}.zip=tint;
        caa{j}.status='submitted';
        caa{j}.timeofrequest=now;
        flag_check_status_of_downloads=1; 
    else
        help caa_download;return;
    end
end

if flag_check_status_of_downloads,    % check/show status of downloads
    disp('=== status of jobs (saved in file .caa) ====');
    if ~isempty(caa),
        for j=1:length(caa), % go through jobs
            disp([num2str(j) '.' caa{j}.status ' ' caa{j}.dataset '-' caa{j}.tintiso]);
        end
    else
        disp('No active downloads');
        if nargout==1, download_status=1; end
        return;
    end
    j_remove_jobs=zeros(1,length(caa));
    j_finished_jobs=zeros(1,length(caa));
    for j=1:length(caa), % go through jobs
        if strcmpi(caa{j}.status,'downloaded') || strcmpi(caa{j}.status,'finnished') || strcmpi(caa{j}.status,'finished') % 'finnished shoudl be removed after some time % do nothing
            j_finished_jobs(j)=1;
        elseif strcmpi(caa{j}.status,'submitted'),
            disp(['=== Checking status of job nr: ' num2str(j) '==='])
            temp_file=tempname;
            [f,status]=urlwrite(caa{j}.zip,temp_file);
            if status == 0,
                disp(['STILL WAITING TO FINISH, submitted ' num2str((now-caa{j}.timeofrequest)*24*60,3) 'min ago.']);
                if now-caa{j}.timeofrequest>1, % waiting more than 1 day
                    y=input('Waiting more than 24h. Delete from list? y/n :','s');
                    if strcmpi(y,'y'),
                        j_remove_jobs(j)=1;
                    end
                end
            else
                filelist=unzip(temp_file);
                move_to_caa_directory(filelist);
                delete(f);
                caa{j}.status='FINISHED';
                save -mat .caa caa; % changes in caa saved
            end
        else
            disp('ERROR: Unknown status!')
            return
        end
    end
    if sum(j_finished_jobs)>5, % ask for cleanup
        y=input('Shall I remove FINISHED from the list? y/n :','s');
        if strcmpi(y,'y'),
            j_remove_jobs=j_remove_jobs | j_finished_jobs;
        end
    end
    caa(j_remove_jobs==1)=[];
    save -mat .caa caa;
    return;
end


flag_test=0; % do not use caa_test_query
flag_wildcard=1; % default is to use wildcard
flag_check_if_there_is_data=1; % check if there are any at caa
nonotify='&nonotify=1'; % default is not notify by email

if nargin==3 && strcmpi(flags,'test'),
    flag_test=1;
    nonotify=''; % notify also by email
elseif nargin==3 && strcmpi(flags,'nowildcard'),
    flag_wildcard=0;
    flag_check_if_there_is_data=0;
    nonotify='&nonotify=1';
end

if ~exist('CAA','dir'), mkdir('CAA');end
if isnumeric(tint), % assume tint is epoch
    tintiso=irf_time(tint,'tint2iso');
elseif ischar(tint), % tint is in isoformat
    tintiso=tint;
else % unknown format
    disp(tint);
    error('caa_download: unknown tint format');
end

if flag_wildcard, % expand wildcards
    dataset(strfind(dataset,'?'))='*'; % substitute  ? to * (to have the same convention as in irf_ssub)
    dataset(strfind(dataset,'_'))='*'; % substitute  _ to * (to handle CIS products that can have - instead of _)
end

if strfind(dataset,'list'), % list  files
    if strcmpi(dataset,'list'), % list all files
        filter='*';
    else                        % list only filtered files
        filter=dataset(strfind(dataset,':')+1:end);
    end
    %    url_line_list=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
    %        filter '&time_range=' tintiso '&format=cdf&list=1'];
    %    url_line_list=['http://caa.estec.esa.int/caa_test_query/?uname=vaivads&pwd=caa&dataset_id=' ...
    %        filter '&time_range=' tintiso '&format=cdf&list=1'];
    url_line_list=['http://caa.estec.esa.int/cgi-bin/inventory.cgi/?uname=vaivads&pwd=caa&dataset_id=' filter '&time_range=' tintiso ];
    disp('Be patient! Contacting CAA...');
    caalog=urlread(url_line_list);
    disp(caalog);
    return;
else  % download data
    
    if flag_check_if_there_is_data 
        %    url_line_list=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
        %        dataset '&time_range=' tintiso '&format=cdf&list=1'];
        %    url_line_list=['http://caa.estec.esa.int/caa_test_query/?uname=vaivads&pwd=caa&dataset_id=' ...
        %        dataset '&time_range=' tintiso '&format=cdf&list=1'];
        url_line_list=['http://caa.estec.esa.int/cgi-bin/inventory.cgi/?uname=vaivads&pwd=caa&dataset_id=' dataset '&time_range=' tintiso];
        disp('Be patient! Contacting CAA to see the list of files...');
        caalist=urlread(url_line_list);
        disp(caalist);
        if ~any(strfind(caalist,'Version')),% there are no CAA datasets available
            disp('There are no CAA data sets available!');
            return;
        end
    end
    
    if flag_test,
        url_line=['http://caa5.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
            dataset '&time_range=' tintiso '&format=cdf&file_interval=72hours' nonotify];
%        url_line=['http://caa.estec.esa.int/caa_test_query/?uname=vaivads&pwd=caa&dataset_id=' ...
%            dataset '&time_range=' tintiso '&format=cdf&schedule=1&file_interval=72hours'];
    else
        url_line=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
            dataset '&time_range=' tintiso '&format=cdf2.7&file_interval=72hours' nonotify];
% temporaly commented out because by default caa returns cdf 3.3.1 format, but matlab does
% not support CDFEPOCH16 in that format
%        url_line=['http://caa.estec.esa.int/caa_query/?uname=vaivads&pwd=caa&dataset_id=' ...
%            dataset '&time_range=' tintiso '&format=cdf&file_interval=72hours' nonotify];
    end
    
    disp('Be patient! Submitting data request to CAA...');
    disp(url_line);
    
    temp_file=tempname;
    urlwrite(url_line,temp_file);
    disp(['url response downloaded to file:' temp_file]);
    try
        filelist=unzip(temp_file);
        disp('unzipped data files.');
        move_to_caa_directory(filelist);
        delete(temp_file);
        if nargout==1, download_status=1;end
    catch 
        irf_log('fcal','Could not find zip file with data! ');
        fid=fopen(temp_file);
        while 1
            tline = fgetl(fid);
            if ~ischar(tline), break, end
            disp(tline)
            if any(strfind(tline,'http:')) && any(strfind(tline,'zip')),
                downloadfile = tline(strfind(tline,'http:'):strfind(tline,'zip')+3);
            end
        end
        fclose(fid);
        delete(temp_file);
        
        if exist('downloadfile','var'),
            j=length(caa)+1;
            caa{j}.url=url_line;
            caa{j}.dataset=dataset;
            caa{j}.tintiso=tintiso;
            caa{j}.zip = downloadfile;
            caa{j}.status = 'SUBMITTED';
            caa{j}.timeofrequest = now;
            if nargout==1, download_status=0; end
            
            disp('=====');
            disp('The request has been put in queue');
            disp(['When ready data will be downloaded from: ' downloadfile]);
            disp('To check the status of jobs execute: caa_download');
            
            save -mat .caa caa
        else
            disp('!!!! Did not succeed to download !!!!!');
            download_status=0;
        end
    end
end

function move_to_caa_directory(filelist)
for jj=1:length(filelist),
    ii=strfind(filelist{jj},filesep);
    if numel(ii)==2, % dataset files (cdf_convert_summary.log not copied)
        dataset=filelist{jj}(ii(1)+1:ii(2)-1);
        disp(['Data set: ' dataset '--> CAA/']);
        if ~exist(['CAA/' dataset],'dir'), mkdir(['CAA/' dataset]);end
        movefile(filelist{jj},['CAA/' dataset]);
    end
end
%disp(['REMOVING DATA DIRECTORIES & FILES: ' filelist{jj}(1:ii(1)) ',delme.zip']);
rmdir(filelist{jj}(1:ii(1)),'s');

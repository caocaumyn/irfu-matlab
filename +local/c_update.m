function c_update(datasetName)
% LOCAL.C_UPDATE update index information in CAA directory
%
%    LOCAL.C_UPDATE update index for all datasets
% 
%    LOCAL.C_UPDATE(datasetName) update only the index of dataset datasetName 
%
% See also:
%	LOCAL.C_READ

%% list all available datasets
dirCaa='/data/caalocal';
cd(dirCaa);
tmp=dir(dirCaa);
iDir = [tmp(:).isdir]; % find directories
dataSetArray = {tmp(iDir).name}';
dataSetArray(ismember(dataSetArray,{'.','..'})) = []; % remove '.' and '..'

%% if index only selected datasetName, remove others
if nargin == 1 && ischar(datasetName)
  dataSetArray(~ismember(dataSetArray,{datasetName})) = []; 
end

%% go through all the datasets to be indexed
for iDataSet=1:numel(dataSetArray)
	%% list files in data set directory
	dataSet=dataSetArray{iDataSet};
	irf_log('fcal',['Indexing data set: ' dataSet]);
	dataSet=replace_minus_in_cis_names(dataSet);
	listFiles=dir([dataSet '/*.cdf']);
	iDir = [listFiles(:).isdir]; %# returns logical vector
	listFiles(iDir)=[];
	if numel(listFiles)==0, 
		irf_log('dsrc','No data files');
		continue;
	end
	%% read in file time intervals
	listFileNames=vertcat(listFiles.name);
	tmp=[listFileNames listFileNames(:,end)]; % add one more column at the end
	tmp(:,end)='=';       % change end column to character = (used as separator)
	tmp=tmp';
	tt=textscan(regexprep(tmp(:)','__',' '),'%*[^ ] %4f%2f%2f_%2f%2f%2f_%4f%2f%2f_%2f%2f%2f%*s','delimiter','=');
	%% create index
	index.filename=[repmat([dataSet filesep],numel(listFiles),1) listFileNames];
	index.tstart=irf_time([tt{1} tt{2} tt{3} tt{4} tt{5} tt{6}],'vector2epoch');
	index.tend=irf_time([tt{7} tt{8} tt{9} tt{10} tt{11} tt{12}],'vector2epoch');
	eval(['index_' dataSet '=index;']);
	dirsave('index',['index_' dataSet]);
end

	function dataSetOut=replace_minus_in_cis_names(dataSet)
		if strfind(dataSet,'CIS'),
			if strfind(dataSet,'-'),
			irf_log('dsrc',['Replacing minus signs in dataset: ' dataSet]),
			dataSetNew=strrep(dataSet,'-','_');
			irf_log('dsrc',['New data set: ' dataSetNew]);
			eval(['!mv ' dataSet ' ' dataSetNew]);
			dataSet=dataSetNew;
			end
			listFiles=dir(dataSet);
			iDir = [listFiles(:).isdir]; %# returns logical vector
			listFiles(iDir)=[];
			%% read in file time intervals
			listFileNames=vertcat(listFiles.name);
			if strfind(listFileNames(:)','-'), % files names to be updated
				cd(dataSet);
				for j=1:size(listFileNames),
					fileName=listFileNames(j,:);
					if strfind(fileName,'-'),
						fileNameNew=strrep(fileName,'-','_');
						evalStr=['!mv ' fileName ' ' fileNameNew];
						irf_log('fcal',evalStr);
						eval(evalStr);
					end
				end
				cd('..');
			end
		end
		dataSetOut=dataSet;



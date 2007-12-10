function out = irf_resamp(x,y,varargin)
%IRF_RESAMP   Resample X to the time line of Y
%
% if sampling of X is more than two times higher than Y, we average X,
% otherwise we interpolate X.
%
% out = irf_resamp(X,Y,[METHOD],['fsample',FSAMPLE],['thresh',THRESH])
% method - method of interpolation 'spline', 'linear' etc. (default 'linear')
%          if method is given the interpolate independant of sampling
% fsample - sampling frequency of the Y signal
% thresh - points above STD*THRESH are disregarded for averaging
%
% See also INTERP1
%
% $Id$

% ----------------------------------------------------------------------------
% "THE BEER-WARE LICENSE" (Revision 42):
% <yuri@irfu.se> wrote this file.  As long as you retain this notice you
% can do whatever you want with this stuff. If we meet some day, and you think
% this stuff is worth it, you can buy me a beer in return.   Yuri Khotyaintsev
% ----------------------------------------------------------------------------

error(nargchk(2,8,nargin))

have_options = 0;
args = varargin; 
if nargin > 2, have_options = 1; end

% Default values that can be override by options
sfy = [];
thresh = 0;
method = '';
flag_do='check'; % if no method check if interpolate or average

while have_options
	l = 1;
	switch(lower(args{1}))
		case {'nearest','linear','spline','pchip','cubic','pchip','v5cubic'}
			method = args{1};
			flag_do='interpolation'; % if method is given do interpolation
		case 'method'
			if length(args)>1
				if ischar(args{2})
					method = args{2};
					l = 2;
					flag_do='interpolation'; % if method is given do interpolation
				else irf_log('fcal,','wrongArgType : METHOD must be numeric')
				end
			else irf_log('fcal,','wrongArgType : METHOD value is missing')
			end
		case 'fsample'
			if length(args)>1
				if isnumeric(args{2})
					sfy = args{2};
					l = 2;
				else irf_log('fcal,','wrongArgType : FSAMPLE must be numeric')
				end
			else irf_log('fcal,','wrongArgType : FSAMPLE value is missing')
			end
		case {'thresh','threshold'}
			if length(args)>1
				if isnumeric(args{2})
					thresh = args{2};
					l = 2;
				else irf_log('fcal,','wrongArgType : THRESHOLD must be numeric')
				end
			else irf_log('fcal,','wrongArgType : THRESHOLD value is missing')
			end
		otherwise
			irf_log('fcal',['Skipping parameter ''' args{1} ''''])
			args = args(2:end);
	end
	args = args(l+1:end);
	if isempty(args), break, end
end

% return in case inputs are empty
if numel(x)==0 || numel(y)==0
    out=[];return;
end

% construct output time axis
if size(y,2)==1, t = y(:); % y is only time
else t = y(:,1); t = t(:);   % first column of y is time
end
ndata = length(t);

if size(x,1) == 1,            % if X has only one point, this is a trivial
                              % case and we return directly
  out = [t (t*0+1)*x(:,2:end)];
  return
end

if strcmp(flag_do,'check'), % Check if interpolation or average
	if ndata>1 
		% If more than one output time check sampling frequencies
		% to decide interpolation/average
		
		% Guess samplings frequency for Y
		if isempty(sfy)
			sfy1 = 1/(t(2) - t(1));
			if ndata==2, sfy = sfy1;
			else
				not_found = 1; cur = 3; MAXTRY = 10;
				while (not_found && cur<=ndata && cur-3<MAXTRY)
					sfy = 1/(t(cur) - t(cur-1));
					if abs(sfy-sfy1)<sfy*0.001
						not_found = 0;
						sfy = (sfy+sfy1)/2;
						break
					end
					cur = cur + 1;
				end
				if not_found
					sfy = sfy1;
					irf_log('proc',	sprintf(...
						'Cannot guess sampling frequency. Tried %d times',MAXTRY));
				end
			end
			clear sfy1
		end
		
		if length(x(:,1))/(x(end,1) - x(1,1)) > 2*sfy
			flag_do='average';
		else
			flag_do='interpolation';
		end
	else
		flag_do='interpolation';  % If one output time then do interpolation
	end
end

if strcmp(flag_do,'average')
	dt2 = .5/sfy; % Half interval
	if exist('irf_average_mx','file')~=3
		irf_log('fcal','cannot find mex file, defaulting to Matlab code.')
		out = zeros(ndata,size(x,2));
		out(:,1) = t;
		for j=1:ndata
			ii = find(x(:,1) <=  t(j) + dt2 & x(:,1) >  t(j) - dt2);
			if isempty(ii), out(j,2:end) = NaN;
			else
				if thresh % Throw away points above THERESH*STD()
					sdev = std(x(ii,2:end)); 
					mm = mean(x(ii,2:end));
					if any(~isnan(sdev))
						for k=1:length(sdev)
							if ~isnan(sdev(k))
								kk = find( abs( x(ii,k+1) -mm(k) ) <= thresh*sdev(k));
								%disp(sprintf(...
								%	'interval(%d) : disregarding %d 0f %d points',...
								%	j, length(ii)-length(kk),length(ii)));
								if ~isempty(kk), out(j,k+1) = mean(x(ii(kk),k+1));
								else out(j,k+1) = NaN;
								end
							else out(j,k+1) = NaN;
							end
						end
					else out(j,2:end) = NaN;
					end
				else out(j,2:end) = mean(x(ii,2:end));
				end
			end
		end
	else
		out = irf_average_mx(x,t,dt2,thresh);
	end
elseif strcmp(flag_do,'interpolation'),
  if nargin < 3, method = 'linear'; end

  % If time series agree, no interpolation is necessary.
  if size(x,1)==size(y,1), if x(:,1)==y(:,1), out = x; return, end, end

  out = [y(:,1) interp1(x(:,1),x(:,2:end),y(:,1),method,'extrap')];
end

function [output_string]=irf_ssub(input_string,varargin)
%IRF_SSUB   Substitute strings 
% 
% Change all appearences of '?' and/or '!' and/or '$' in string 
% to some number (numbers can be also strings or cells with string)
%
% [OUTPUT_STRING]=IRF_SSUB(INPUT_STRING,NUM) change all appearence of '?' 
% in INPUT_STRING to NUM. NUM is converted to string using NUM2STR function
%
% [OUTPUT_STRING]=IRF_SSUB(INPUT_STRING,NUM1,[NUM2],[NUM3])
%  change all appearences of '?' to NUM1, '!' to NUM2, and '$' to NUM3
%
% Example: 
%	for ic=1:4,eval(irf_ssub('R?=r?;C?=R?.^2;',ic)),end
%     is the same as R1=r1;C1=R1.^2;R2=r2;C2=R2.^2;...
%
% See also:
%       C_EVAL
%
% $Id$

narginchk(2,4)

output_string = input_string;
symb = '?!$';

for j=nargin-1:-1:1
    if ischar(varargin{j}),
        output_string=strrep(output_string,symb(j),varargin{j});
    elseif isnumeric(varargin{j}),
        output_string=strrep(output_string,symb(j),num2str(varargin{j}));
    elseif iscell(varargin{j}), % use only the first cell
        output_string=strrep(output_string,symb(j),varargin{j}{1});
    else
        irf_log('fcal','Cannot understand input, see help!');
    end
end

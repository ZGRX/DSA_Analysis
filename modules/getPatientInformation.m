function varargout = getPatientInformation(varargin)
% Wrapper for backward compatibility: forwards to modules/io/io_getPatientInformation
    [varargout{1:nargout}] = io_getPatientInformation(varargin{:});
end

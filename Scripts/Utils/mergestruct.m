function s_merged = mergestruct(s1, s2)
% MERGESTRUCT Merge two structs, with s2 values taking precedence for overlapping fields
%
% Usage:
%   s_merged = mergestruct(s1, s2)
%
% This function combines two structs, with s2 fields overwriting s1 fields
% in case of name conflicts. Useful for merging baseline and enhanced metrics.

    s_merged = s1;
    
    if isempty(s2)
        return;
    end
    
    fields = fieldnames(s2);
    for i = 1:numel(fields)
        s_merged.(fields{i}) = s2.(fields{i});
    end
end

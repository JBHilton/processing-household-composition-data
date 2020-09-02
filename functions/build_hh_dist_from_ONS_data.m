function [composition_list,composition_dist] = build_hh_dist_from_ONS_data(hh_data,resolution)
% build_uk_hh_dist_from_ONS_data takes a table of household composition
% data and a specified output area resolution as input and returns a
% histogram of household compositions for each output area at the specified
% resolution.

%  The household composition data is assumed to be in the format used by
%  the ONS, i.e. columns specifying nested output areas followed by columns
%  specifying the number of people of each age class present, followed by a
%  column specifying the number of households in that composition in that
%  output area. The 'resolution' input should match the table header for
%  the desired output area resolution in the ONS tables.To obtain a single
%  histogram for the entirety of England and Wales, set resolution to
%  'ALL'. Note that execution time may be very slow when working with very
%  fine spatial resolutions and a large number of age classes. It is also
%  important to keep in mind that the set of histograms at the finest
%  resolution specified in the ONS tables is precisely what the tables
%  themselves record, so users should never need to run this function at
%  that level of resolution.

numstart=find(varfun(@isnumeric,hh_data,'OutputFormat','uniform'),1);

if strcmp(resolution,'ALL')
    no_OAs = 1;
else
    OA_list = unique(hh_data.(resolution)); % Get a list of all the output areas
    no_OAs = length(OA_list);
end
raw_composition_list = hh_data(:,numstart:width(hh_data)-1);
raw_composition_list=table2array(raw_composition_list);
[raw_no_compositions, ~]=size(raw_composition_list);
max_by_class = max(raw_composition_list);
encoder = [1 cumprod(1+max_by_class(1:end-1))];
raw_encoded_list = raw_composition_list*encoder';
count_list = hh_data.count;

composition_list = unique(raw_composition_list,'rows');
encoded_list = composition_list*encoder';
decoder_length = max(encoded_list);
decoder=sparse(decoder_length,1);
no_compositions = length(encoded_list);
for i=1:no_compositions
    decoder = decoder+sparse(encoded_list(i),1,i,decoder_length,1);
end

composition_dist = zeros(no_compositions,no_OAs);
starttime=cputime;
if strcmp(resolution,'ALL')
        for j=1:raw_no_compositions
            this_comp = decoder(raw_encoded_list(j));
            composition_dist(this_comp) = composition_dist(this_comp)+count_list(j);
        end
else
    for i=1:no_OAs
        current_OA = OA_list(i);
        disp(['Now doing ' current_OA{:} ', region ' num2str(i) ' of ' num2str(no_OAs) '.']);
        current_range=find(strcmp(hh_data.(resolution),current_OA));
        for j=1:length(current_range)
            this_comp = decoder(raw_encoded_list(current_range(j)));
            composition_dist(this_comp,i) = composition_dist(this_comp,i)+count_list(current_range(j));
        end
        disp([num2str(cputime-starttime) ' elapsed, estimated ' num2str((no_OAs-i)*(cputime-starttime)/i) ' remaining.']);
    end
end

total_households = sum(composition_dist);
composition_dist = composition_dist./total_households;
composition_dist(isnan(composition_dist)) = 0;

composition_list = array2table(composition_list);
composition_dist = array2table(composition_dist);
composition_list.Properties.VariableNames = hh_data.Properties.VariableNames(numstart:end-1);
if ~strcmp(resolution,'ALL')
    composition_dist.Properties.VariableNames = OA_list;
end

end
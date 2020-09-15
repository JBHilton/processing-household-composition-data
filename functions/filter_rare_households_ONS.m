function filtered_hh_data = filter_rare_households_ONS(hh_data,p)
% filter_rare_households_uk takes a table of household composition data and
% a value p between 0 and 1 as input and returns a table containing the
% same data with the largest households, corresponding to the top 100*p
% percent of the population, removed. The household composition data is
% assumed to be in the format used by the ONS, i.e. columns specifying
% nested output areas followed by columns specifying the number of people
% of each age class present, followed by a column specifying the number of
% households in that composition in that output area.

numstart=find(varfun(@isnumeric,hh_data,'OutputFormat','uniform'),1); % This finds where OA codes stop and numbers start

hh_size_list = sum(hh_data{:,numstart:end-1},2);
weighted_sizes = hh_size_list.*hh_data.count;
prop_by_size = zeros(max(hh_size_list),1);
pop_size = sum(weighted_sizes);
for i=1:max(hh_size_list)
    prop_by_size(i) = sum(weighted_sizes(hh_size_list>=i))/pop_size; % Proportion of population in households of size i or greater
end

rare_bd = find(prop_by_size<p,1);

lower_one_minus_p = find(hh_size_list<rare_bd);

filtered_hh_data = hh_data(lower_one_minus_p,:);

end
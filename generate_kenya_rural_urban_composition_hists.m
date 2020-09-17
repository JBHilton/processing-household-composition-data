% This gets histograms for HH compositions for urban and rural populations from DHS data

dhs_data=readtable('data/kenya_urban_rural_ages.csv');
dhs_data.Properties.VariableNames(1) = {'residence_type'};
max_no_members = width(dhs_data)-1;
max_no_members = width(dhs_data)-1;
hh_member_string = cell(1,max_no_members);
for i=1:max_no_members
    hh_member_string{i} = ['age_' num2str(i)];
end
dhs_data.Properties.VariableNames(2:end) = hh_member_string;

urban_locs = dhs_data.('residence_type')==1;
age_samples = table2array(dhs_data(:,2:end));

age_class_bds = 0:5:80;
no_age_classes = length(age_class_bds);

size_samples = sum(~isnan(age_samples),2);
no_samples = length(size_samples);
comp_samples = zeros(no_samples,no_age_classes);
for i=1:no_samples
    age_class_list = idivide(int16(age_samples(i,1:size_samples(i))),5)+1;
    age_class_list(age_class_list>no_age_classes) = no_age_classes;
    comp_samples(i,:) = hist(age_class_list,1:no_age_classes);
end

% Build new table containing rural-urban info as well as comps

T = [table(dhs_data.('residence_type')) array2table(comp_samples)];
T.Properties.VariableNames(1) = {'residence_type'};
age_string = cell(1,no_age_classes);
for i=1:no_age_classes-1
   age_string{i} = ['no_' num2str(age_class_bds(i)) '_to_' num2str(age_class_bds(i+1))];
end
age_string{no_age_classes} = ['no_' num2str(age_class_bds(end)) '_plus'];
T.Properties.VariableNames(2:end) = age_string;

% Now through away 0.1% of pop belonging to largest households

pop_size = sum(size_samples);
prop_by_size = zeros(1,max_no_members);
for i=1:max_no_members
    prop_by_size(i) = sum(size_samples(size_samples>=i))/pop_size;
end
rare_bd = find(prop_by_size<1e-3,1);
lower_99 = find(size_samples<rare_bd);
T = T(lower_99,:);
filtered_comps = comp_samples(lower_99,:);
urban_status = T.('residence_type');

% Here are a few natural aggregations of age classes:

% 10 year age bands:
% filtered_comps = [filtered_comps(:,2:2:16)+filtered_comps(:,1:2:15), filtered_comps(:,end)];
% 5 year age bands, 20-60 merged
% filtered_comps = [filtered_comps(:,1:4) sum(filtered_comps(:,5:12),2) filtered_comps(:,13:end)];
% 10 year age bands, 20-60 merged
% filtered_comps = [filtered_comps(:,2:2:16)+filtered_comps(:,1:2:15), filtered_comps(:,end)];
% filtered_comps = [filtered_comps(:,1:2) sum(filtered_comps(:,3:6),2) filtered_comps(:,7:end)];
% 0-20-60, 5yr bands
% filtered_comps = [sum(filtered_comps(:,1:4),2) sum(filtered_comps(:,5:12),2) filtered_comps(:,13:end)];
% 0-20-60, 10yr bands
% filtered_comps = [filtered_comps(:,2:2:16)+filtered_comps(:,1:2:15), filtered_comps(:,end)];
% filtered_comps = [sum(filtered_comps(:,1:2),2) sum(filtered_comps(:,3:6),2) filtered_comps(:,7:end)];
% 0-20-60+
filtered_comps = [sum(filtered_comps(:,1:4),2) sum(filtered_comps(:,5:12),2) sum(filtered_comps(:,13:end),2)];
max_by_class = max(filtered_comps);
encoder = [1 cumprod(1+max_by_class(1:end-1))];
encoded_samples = filtered_comps*encoder';
composition_list = unique(filtered_comps,'rows','stable');
encoded_list = composition_list*encoder';
decoder_length = max(encoded_list);
decoder=sparse(decoder_length,1);
no_compositions = length(encoded_list);
for i=1:no_compositions
    decoder = decoder+sparse(encoded_list(i),1,i,decoder_length,1);
end

composition_dist = zeros(no_compositions,2);
starttime=cputime;
ur = {'urban','rural'};
for i=1:2
    disp(['Now doing ' ur{i} '.']);
    current_range=find(T.('residence_type')==i);
    for j=1:length(current_range)
        this_comp = decoder(encoded_samples(current_range(j)));
        composition_dist(this_comp,i) = composition_dist(this_comp,i)+1;
    end
    disp([num2str(cputime-starttime) ' elapsed, estimated ' num2str((2-i)*(cputime-starttime)/i) ' remaining.']);
end

total_households = sum(composition_dist);
composition_dist = composition_dist./total_households;
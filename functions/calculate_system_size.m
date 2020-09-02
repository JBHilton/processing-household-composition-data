function system_size = calculate_system_size(composition_list,no_comps)
% calculate_system_size calculates the number of states in a stochastic
% age-and-household structured epidemic model using the composition data
% defined by composition_list and a number of epidemiological compartments
% defined by no_comps.

[no_types, ~] = size(composition_list); % To avoid confusion between COMPosition and COMPartment, we here call the compositions household typs

classes_present = composition_list>0; % For each composition this indicates which classes are contained in the household

% In the following loop, we calculate the number of ways we can assign the
% members of each class in each household to the specified number of
% epidemiological compartments. The number of states a household of a given
% composition can be in is the product of all the ways we can assign the
% members of each class (since the set of possible assignments of each
% class is independent of how the other classes are assigned).
system_sizes = ones(no_types,1);
for i=1:no_types
    for j=find(classes_present(i,:))
        system_sizes(i) = system_sizes(i)*... This is the "stars and bars" formula from combinatorics
            nchoosek(composition_list(i,j)+no_comps-1,no_comps-1);
    end
end

% The total number of states the stochastic model has is the sum of the
% number of states which each household type can occupy:
system_size = sum(system_sizes);

end
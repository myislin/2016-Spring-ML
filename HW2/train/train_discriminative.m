clear;

alpha = 0.1;

data = load('../data/Training_data_hw2.mat');
result = load('./train_result.mat');

% calculate how many classes: 4 in this case
num_class = size(data.T_train,2);
% 4 X 3 matrix, summation of data by each class
sum_by_class = data.T_train' * data.Phi_train;
% 1 X 4 vector, calculate how much data by each class
tot_num_class = sum(data.T_train(:,1:num_class));
% calculate the mean of each class
mean_class = sum_by_class ./ tot_num_class';
% Total number of data
tot_num_data = sum(tot_num_class);

phi = data.Phi_train;
phi(:,end+1) = 1;

% calculate the dimension of the Phi
dim_phi = size(phi,2);

% get w from the result of generative method
w = result.w_g;
w(end+1,:) = 1;

% initialize y
for j=1:1:tot_num_data
	for i=1:1:num_class
		y(j,i) = exp(phi(j,:)*w(:,i));
	end
end
% normalize y to real probability
y ./= sum(y,2);
%for i=1:1:tot_num_data
%	y(i,:) = [0.25 0.25 0.25 0.25];
%end
predict_mtx = all(y==max(y,[],2),3);

correct_mtx = data.T_train - predict_mtx;
correct_vec = all(correct_mtx==0,2);
correct_num = sum(correct_vec);
error_rate = (tot_num_data - correct_num)/ tot_num_data * 100

% transfer w to 16x1 vector (w_d)
for i=1:1:num_class
	w_d(end+1:end+dim_phi,1) = w(:,i);
end

I = diag(ones(num_class,1));

error_rate_last = error_rate;
while 1

for i=1:1:num_class
	idx = (i-1)*dim_phi + 1;
	dE(idx:idx+dim_phi-1,1) = sum((y(:,i) - data.T_train(:,i)) .* phi);
end

% build hessian matrix H
for j=1:1:num_class
	for k=1:1:num_class
		acc_mtx = zeros(dim_phi);
		for i=1:1:tot_num_data
			acc_mtx += y(i,k)*(I(k,j) - y(i,j))*phi(i,:)'*phi(i,:);
		end
		idx_j = (j-1)*dim_phi + 1;
		idx_k = (k-1)*dim_phi + 1;
		H(idx_j:idx_j+dim_phi-1,idx_k:idx_k+dim_phi-1) = -acc_mtx;
	end
end

w_d += alpha*inv(H)*dE;

% transfer w_d to 4x4 matrix w
for i=1:1:num_class
	idx = (i-1) * dim_phi+1;
	w(:,i) = w_d(idx:idx+dim_phi-1,1);
end

% update y from new w_d
for j=1:1:tot_num_data
	for i=1:1:num_class
		y(j,i) = exp(phi(j,:)*w(:,i));
	end
end
% normalize y to real probability
y ./= sum(y,2);

predict_mtx = all(y==max(y,[],2),3);

correct_mtx = data.T_train - predict_mtx;
correct_vec = all(correct_mtx==0,2);
correct_num = sum(correct_vec);
error_rate = (tot_num_data - correct_num)/ tot_num_data * 100

if error_rate >= error_rate_last
	break;
else
	error_rate_last = error_rate;
end

end

class_1 = predict_mtx(:,1) .* phi;
class_1(all(class_1==0,2),:) = [];
scatter3(class_1(:,1), class_1(:,2), class_1(:,3), [], [1 0 0])
hold on
class_2 = predict_mtx(:,2) .* phi;
class_2(all(class_2==0,2),:) = [];
scatter3(class_2(:,1), class_2(:,2), class_2(:,3), [], [0 1 0])
hold on
class_3 = predict_mtx(:,3) .* phi;
class_3(all(class_3==0,2),:) = [];
scatter3(class_3(:,1), class_3(:,2), class_3(:,3), [], [0 0 1])
hold on
class_4 = predict_mtx(:,4) .* phi;
class_4(all(class_4==0,2),:) = [];
scatter3(class_4(:,1), class_4(:,2), class_4(:,3), [], [1 1 0])

save -append -mat "./train_result.mat" w_d;

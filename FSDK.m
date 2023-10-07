function [X_select,Obj_w,idxw,fea_id,t,converge] = FSDK(X,label,s_num,gamma,p,NITR_w,NITR_y)

% X��ԭʼ���ݾ��� n*d

% label����ʵ����ǩ n*1

% s_num������ѡ������

% p��2,p��������������0,2]

% gamma��2,p���������򻯲�����
       % gammaԽ��Խ�ӽ�F������W��ϡ����Խ����p>=1ʱΪ͹
       % gammaԽС��Խ�ӽ�2,0������W��ϡ����Խǿ��0<p<1ʱΪ��͹
       
% NITR_w��������W��b���ܵ�������

% NITR_y����������ɢY�ĵ�������

%% ��������

if nargin < 7
    NITR_y = 20; % �ڻ�����������30��
end
if nargin < 6
    NITR_w = 30; % �⻷����������30��
end
if nargin < 5
    p = 1;       % ������Ĭ��2,1����
end
if nargin < 4
    gamma = 100;
end
if nargin == 2
    error('���ڵ���������������ѡ�����������')
end
if nargin < 2
    error('������ԭʼ���ݺ���ʵ��ǩ')
end

%% ���� �������ľ����ʱ�临�Ӷ���O(nd)
X = X';
[d,n] = size(X);
% H = eye(n)-ones(n)./n;
X_mean = mean(X,2);          % ʱ�临�Ӷ�O(nd)
X = X - X_mean;              % ԭʼ�������Ļ� ʱ�临�Ӷ�O(nd)
% X = X * H;
c = length(unique(label));   % ��ʵ�������
converge = true;             % �����߼�ֵ

%% ��ʼ�� rand��ʼ����ʱ�临�Ӷ���O(nc)
err_objw = 1;                % Ŀ�꺯����
iter = 1;                    % while�е�������
U = eye(d);                  % ��ʼ���Խ���U����2,p�������
pause(0)
tic
init_Y = 'rand';             % Y����ĳ�ʼ����ʽ
switch init_Y
    case 'rand'              % Y���������ʼ��
        Y = zeros(n,c);
        for i = 1:n
            Y(i,randperm(c,1)) = 1;
        end
    case 'kmeans'                                            % ����K-means��ʼ��
        [idx] = kmeans(X',c);
        Y = n2nc(idx,c);
end
G = Y*(Y'*Y+eps*eye(c))^(-0.5);                              % ʱ�临�Ӷ�O(n*c^2)+O(c^3)


% Clus_resultY = zeros(NITR_w+1,3);
% labelpre = labelconvert(Y);
% Clus_resultY(1,:) = ClusteringMeasure(labelpre,label);
%% Fix Y and update W,b
while iter<= NITR_w
    % �̶�Y������W ��Algorithm 1��
    b = (G'*ones(n,1))./n;                                   % ����b ʱ�临�Ӷ�O(n*c)+O(c)
    WUiter = 'Once';
    switch WUiter
        case 'Once'
%             P = X'*(X*X'+ gamma*U + eps.*eye(d))^(-1)*X+(1/n)*ones(n);
%             a = svd(P); e = rank(P);
            W = (X*X'+ gamma*U + eps.*eye(d))^(-1)*X*G;                  % ����W��ֻ����һ��
            twopnormw = zeros(d,1);
            for j = 1:d
                U(j,j) = (0.5*p)/((norm(W(j,:),2)^2)^(1-0.5*p)+eps);
                twopnormw(j) = norm(W(j,:),2)^p;                         % ��W����U
            end
        case 'NITR'
            uw = 10;
            for u = 1:uw
                W = (X*X'+ gamma*U + eps.*eye(d))^(-1)*X*G;              % ����W ʱ�临�Ӷ�O(n*d^2)+O(d^3)+O(n*c*d)
                twopnormw = zeros(d,1);
                for j = 1:d                                              % ����ѭ����ʱ�临�Ӷ�ΪO(cd)
                    U(j,j) = (0.5*p)/((norm(W(j,:),2)^2)^(1-0.5*p)+eps); % ���¶ԽǾ���U
                    twopnormw(j) = norm(W(j,:),2)^p;
                end
            end
    end
    
    
    
    % �̶�W������Y ��Algorithm 2��
    [Y,~,~] = updateY(X,W,b,Y,c,NITR_y); % ����Y  ���Ӷ�ΪNITR_y * O(n*c+n*c^2+c^3+n^2*c)+O(n^2*d+n*d^2+d^3) ���Ӷ�...
    G = Y*(Y'*Y+eps*eye(c))^(-0.5);
    
%     labelpre = labelconvert(Y);
%     Clus_resultY(iter,:) = ClusteringMeasure(labelpre,label);
    
    
    % �⻷һ�ָ��½��������Ŀ�꺯��ֵ
    Obj_w(iter) = norm(X'*W + ones(n,1)*b'- G,'fro')^2 ++ gamma*sum(twopnormw); % W���������� 
    
    
    
    % �жϵ����Ƿ�����
    if iter>1
        err_objw = Obj_w(iter)-Obj_w(iter-1);
        if err_objw > 0
            converge = false;
        end
    end
    if iter>2 && abs(err_objw)<1e-3
        break;
    end
    
%     if iter == 1
%         Obj_y0 = Obj_y;
%         figure(1)
%         x = 1:1:size(Obj_y,1);
%         plot(x,Obj_y,'-o','MarkerSize',6,'linewidth',1.5,'Color',[0.8477 0.0156 0.1602]); % ���ڵ�һ�ε���
%         xlabel('The Number of Iterations')
%         ylabel('Objective Value')
%         grid on;
%     end
    iter = iter+1;
end


%% ����ѡ��
score = sum((W.*W),2);
[~,idxw] = sort(score,'descend');
t = toc;
fea_id = idxw(1:s_num);
X_select = X(fea_id,:);

%% Ŀ�꺯��
% figure(2)
% x = 1:1:size(Obj_w,2);
% plot(x,Obj_w,'-o','MarkerSize',6,'linewidth',1.5,'Color',[0.4453 0.0352 0.7148]);
% xlabel('The Number of Iterations')
% ylabel('Objective Value')
% grid on;
% grid minor;
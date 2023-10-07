function [Y,Obj_y,changed] = updateY(X,W,b,Y,c,NITR_y)
% X���ݾ���d*n
% WͶӰ����d*c �ѹ̶�
% Y��ɢ�ؾ���n*c G��Ȩ��ɢ�ؾ���n*c  ��Ϊ��ʼ���������Ż�
% c�������
% NITR�� �ܵ�������
% Ƕ��������NITR2�Լ�10�ε���ѭ����NITR��M��Y��������Ĵ�ѭ����10����Ϊ���õ�������Yʱ��Y������Ҳ�������б�ǩ�������仯��
%% ���붨��
if nargin < 6
    NITR_y = 20;                  % ��ѭ��һ��������ڽ���ѭ��һ��M�����Y����
end
[~,n] = size(X);
A = X'*W+ones(n,1)*b';    
% lambda = 1 + eps;

% P = (lambda-1)*eye(n);            % positive semi-definite


% ���³�ʼ��Y����
% [idx] = kmeans(X',c);           % ÿ�θ���Y����kmeans���³�ʼ���ǲ������
% Y = n2nc(idx,c);

% M = P*G+A;                        % O(n^2*c)
M = A;

Obj_y = zeros(NITR_y+1,1);          % ÿ�����������һ��M��Y���¼һ��Ŀ�꺯��ֵ����һ���ǻ�û����ʱ��Ŀ�꺯����Y����ԭ����ʼ����Y
G = Y*(Y'*Y+eps*eye(c))^-0.5;
Obj_y(1) = trace(G'*M);           % δ����ʱ�õ���Ŀ�꺯��ֵ
changed = zeros(NITR_y,10);
% Obj_y(1) = trace(G'*M);
%% ��������
for iter1 = 1:NITR_y             % M��Y��������Ĵ�ѭ��

%     [m,g] = max(M,[],2);         %��Mÿ�����ֵ��������
%     Y = TransformL(g,c);
    yy = sum(Y.*Y);              % y'*y  1*c  O(n*c)
    ym = sum(Y.*M);              % y'*m  1*c  O(n*c)
%     [~,idxi] = sort(m);          % ���´��򣬴����ֵ��С�Ŀ�ʼ���£���
    for iter2 = 1:10  
        % ����ڵ���������ֻҪ��һ������������������˱仯����ôconverged�ͻ��Ϊfalse
        % ��ô����ѭ�������һֱ���������ﵽ������������������ѭ����һ��ĳһ������������������ϵ��
        % û�з����仯��˵���Ѿ���������ôiter2�Ͳ����ٵ����ˣ�������������ʱ�;���Mû���κι�ϵ
        converged = true;
        for i = 1:n                    % ����Y��ÿһ�У���Ӧÿһ�������㣩 ��ѭ�����Ӷ�ΪO(n*c)
%             i = idxi(iter_n);               % M�����ֵС�����ȸ��£����ֵ��ķź���
            mi = M(i,:);                    % M����ĵ�i�� 1*c
%             yi = Y(i,:);                  % Y����ĵ�i�� 1*c
            [~,id0] = find(Y(i,:)==1);      % ���ж�Ӧ����ԭ���Ĺ������ 1*1
            for k = 1:c                     % O(c)
                if k == id0
                    incre_y(k) = ym(k)/sqrt(yy(k)) - (ym(k) - mi(k))/sqrt(yy(k)-1+eps);
                else
                    incre_y(k) = (ym(k)+mi(k))/sqrt(yy(k)+1) - ym(k)/sqrt(yy(k));
                end
            end
                
%             a = ((ym+(1-yi).*mi)./sqrt(yy + 1-yi));
%             b = ((ym-yi.*mi)./(sqrt(yy-yi)+eps)); % ���� 1*c
%             incre_y = a-b;

            [~,id] = max(incre_y);          % ���ж�Ӧ�������º�Ĺ������ 1*1
            if id~=id0
                converged = false;          % ˵��������,n������������ɺ�Ҫ���Ŷ�Y����
                changed(iter1,iter2) = changed(iter1,iter2)+1; % �ۻ��������仯�����������ж�Ӧ��ѭ�����ж�ӦСѭ��
                yi = zeros(1,c);            % ����yi
                yi(id) = 1;                 % Ϊ������ǩ��ֵ
                Y(i,:) = yi;                % ����Y����ĵ�iter_n��
                yy(id0) = yy(id0) - 1;      % id0��ǩ��1���0������yyҪ��һ
                yy(id)  = yy(id) + 1;       % id��ǩ��0���1������yyҪ��һ
                ym(id0) = ym(id0) - mi(id0);% id0��ǩ��1���0������ymҪ��ȥmi��Ӧ��ֵ
                ym(id)  = ym(id) + mi(id);  % id��ǩ��0���1������ymҪ����mi��Ӧ��ֵ
            end
        end
        if converged                        % ����n��������false˵������������������Y��true˵����������ʼ��һ�ָ���M
            break;
        end
    end
    G = Y*(Y'*Y+eps*eye(c))^-0.5;         % ʱ�临�Ӷ�ΪO(n*c^2)+O(c^3)
%     M = P*G+A;                            % ʱ�临�Ӷ�ΪO(n^2*c)
    Obj_y(iter1+1) = trace(G'*M);           % G��Y��ã�M��G��gamma,U,X��ã�ÿһ�ֵ�����U������W����ȱ仯����˾���Y���䣬��Ŀ�꺯��ֵҲ�ᷢ���ϴ�仯
%     if isnan(Obj_y(iter1+1))
%         finalY = Y;
%         finalObj=Nan;
%         break;
%     end
%     if iter1 == 1
%         maxObj=Obj_y(iter1+1);
%         finalY = Y;
%         finalObj=maxObj;
%     else
%         if ~isnan(Obj_y(iter1+1)) && Obj_y(iter1+1) >= maxObj
%             maxObj=Obj_y(iter1+1);
%             finalObj=maxObj;
%             finalY = Y;
%         end
%     end
    if iter1 > 3 && (Obj_y(iter1)-Obj_y(iter1-1))/Obj_y(iter1)<1e-10
%     if iter1 == NITR_y && (Obj_y(iter1)-Obj_y(iter1-1))/Obj_y(iter1)<1e-10
        break;
    end
%     if iter1>30 && sum(abs(Obj_y(iter1-8:iter1-4)-Obj_y(iter1-3:iter1+1)))<1e-10
%         break;
%     end
end
end
    
    
                
            

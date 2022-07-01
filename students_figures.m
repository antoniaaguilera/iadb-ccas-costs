strColors={
'110833'
'5627FF'
'9A7DFF'
'B30AF2'
'72E8CE'
'2AC2B2'
'229B8E'
'ED175F'
'F68CAF'};

pick=[6 8 2] ;

Colors=NaN(length(strColors),3);
for i=1:length(strColors)
Colors(i,:)=sscanf(strColors{i},'%2x%2x%2x',[1 3])/255;
end

[year_proj, textData] = xlsread('/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/data/output_data/students_proj_cl.xlsx');

figure(1)
plot(year_proj(1:end,1),year_proj(1:end,2),'LineWidth',2,'Color',Colors(pick(2),:))
hold on
plot(year_proj(1:end,1),year_proj(1:end,3),'LineWidth',2,'Color',Colors(pick(1),:))
plot(year_proj(1:end,1),year_proj(1:end,4),'LineWidth',2,'Color',Colors(pick(3),:))
hold off
xlim([1 10])
xlabel('Años desde la implementación')
ylabel('MU$D')
grid on
title('Ganancias a 10 Años')
subtitle('Asignación Centralizada de Estudiantes') 
legend('Costos', 'Ahorros', 'Beneficios (simulados)'); 

[pop_proj, textData] = xlsread('/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/data/output_data/students_pop_cl.xlsx');

figure(2)
plot(pop_proj(1:end,3),pop_proj(1:end,2),'LineWidth',2,'Color',Colors(pick(2),:))
hold on
plot(pop_proj(1:end,3),pop_proj(1:end,4),'LineWidth',2,'Color',Colors(pick(1),:))
hold off
xlim([3900, 500000])
xlabel('Número de Postulantes')
ylabel('MU$D')
grid on
title('Ahorro neto según cantidad de postulantes')
subtitle('Asignación Centralizada de Estudiantes') 
legend('Costos', 'Ahorros'); 

[benefit_est, textData] = xlsread('/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/data/for_benefit_estimation.xlsx');

        
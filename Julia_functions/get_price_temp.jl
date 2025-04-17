function get_price_temp(json_file)
    data = JSON3.read(json_file)

    price_EUR = []
    price_NOK = []
    T_out = []
    hour_lst = []

    for i in data
        push!(price_EUR, i["EUR_per_kWh"])
        push!(price_NOK, i["NOK_per_kWh"])
        push!(T_out, i["air_temperature"])
        
        time_str = i["time_start"]
        time_str = replace(time_str, " GMT" => "")
        time_obj = Dates.DateTime(time_str, "e, d u y H:M:S")
        push!(hour_lst, hour(time_obj))

    end

    return price_EUR, price_NOK, T_out, hour_lst
    
end


function get_price_function(price_NOK, tF,σ=0.00001)
    time = LinRange(0, tF, length(price_NOK))  # Lager tidsintervall
    
    return function (t)
        for i in 1:length(time)-1
            if t >= time[i] && t < time[i+1]
                return price_NOK[i]*σ
            end
        end
        return price_NOK[end]*σ  # Returnerer siste verdi hvis t er større enn siste tidsverdi
    end
end

function get_temp_function(temp, tF)
    time = LinRange(0, tF, length(temp))  # Lager tidsintervall
    
    return function (t)
        for i in 1:length(time)-1
            if t >= time[i] && t < time[i+1]
                return temp[i]
            end
        end
        return temp[end]  # Returnerer siste verdi hvis t er større enn siste tidsverdi
    end
end
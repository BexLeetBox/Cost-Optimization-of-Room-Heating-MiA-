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

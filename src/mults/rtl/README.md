approx_0.v    - exact4 ( 0 Approximation, highest increase in power )
approx_1.v    - n1 ( Zacharelos )
approx_2.v    - n2 ( Zacharelos )
approx_3.v    - M1 ( Mohammed Saeed )
approx_4.v    - M2 ( Mohammed Saeed )
approx_5.v    - Kul4 (Kulkarni)
approx_6.v    - Reh4 (Rehman)
approx_7.v    - AxRM a ( mult2a4 )
approx_8.v    - AxRM b ( mult2b4 )
approx_9.v    - OR-based ( Complete Approximation, Highest decrease in Power )

# Numpy Magics
```py
# np.savetxt is really useful
random_array = np.random.randint(0, 10, size=4096)
np.savetxt('array_config.dat', random_array.reshape(1, -1), fmt='%d', delimiter=' ')
```

# No more orphan process
```sh
ps -ef | grep cifar_mat_A_
pkill -f 'cifar_mat_A_'
```


# USEFUL :- notebook in a remote Server
1. ( shh into the server via a aprticular port )
> ssh -L 8080:localhost:8080 paper@172.16.121.48  
2. inside remote 
> jupyter notebook --no-browser --port=8080 ( run this )
3. Copy things to and fro remote server in lab
>  scp -r  paper@172.16.121.48:/path/in/remote /path/in/local
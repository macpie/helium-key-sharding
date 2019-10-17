#!/bin/bash

name=${NAME:-test}
total=${TOTAL:-5}
threshold=${THRESHOLD:-3}

echo "Creating $total shards ($threshold needed to recover) named $name" 

_build/default/rel/key_sharding/bin/key_sharding start
echo "Starting libp2p_crypto"
sleep 10
echo "Generating keys"
_build/default/rel/key_sharding/bin/key_sharding eval 'K = libp2p_crypto:generate_keys(ecc_compact), ok = libp2p_crypto:save_keys(K, "/tmp/keys").'

echo "Loading public key"
pubkey=$(_build/default/rel/key_sharding/bin/key_sharding eval '{ok, #{public := P}} = libp2p_crypto:load_keys("/tmp/keys"), libp2p_crypto:pubkey_to_b58(P).')
echo "PUBLIC KEY $pubkey"
mkdir -p /tmp/shards/$name
cd /tmp/shards/$name
echo $pubkey > pubkey.txt
echo "PUBLIC KEY saved to /tmp/shards/$name/pubkey.txt"

echo "Sharding"
cat /tmp/keys | ~/.cargo/bin/secret-share-split -t $threshold -n $total | split -l 1 -d -a 1 --additional-suffix=-$name.txt

if [ -z "$MOVE" ]
then
    echo "Shards in /tmp/shards/$name"
else 
    move_array=($(echo $MOVE | tr ";" "\n"))
    i=0
    
    for v in "${move_array[@]}"
    do
        echo "Moving /tmp/shards/$name/x$i-$name.txt to $v/x$i-$name.txt"
        mkdir -p $v/
        mv /tmp/shards/$name/x$i-$name.txt $v/$name-shard.txt
        cat $v/$name-shard.txt >> /tmp/key-shards
        ((i++))
    done

   cat /tmp/key-shards | ~/.cargo/bin/secret-share-combine > /tmp/keys2
   pubkey2=$(/opt/key-sharding/_build/default/rel/key_sharding/bin/key_sharding eval '{ok, #{public := P}} = libp2p_crypto:load_keys("/tmp/keys2"), libp2p_crypto:pubkey_to_b58(P).')
    
    if [ "$pubkey" == "$pubkey2" ]; then
        echo "Pubkey are equal we are good"
    else
        echo "PUBKEY ARE DIFF, ABORT ABORT DO NOT USE THIS KEY/SHARDS"
    fi
fi

rm /tmp/key-shards
rm /tmp/keys

echo "Recover with ~/.cargo/bin/secret-share-combine"
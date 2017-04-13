node = :foo@localhost

if Node.connect(node) == true do
  :rpc.call(node, :init, :stop, [])
  IO.puts "Node terminated."
else
  IO.puts "Can't connect to a remote node."
end

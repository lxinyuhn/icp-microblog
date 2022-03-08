import Iter "mo:base/Iter";
import List "mo:base/List";
import Time "mo:base/Time";
import Principal "mo:base/Principal";

actor {
    public type Message = {
        content: Text;
        time: Time.Time;
    };

    public type Microblog = actor {
        follow: shared(Principal) -> async ();
        follows: shared query () -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Time.Time) -> async [Message];
        timeline: shared (Time.Time) -> async [Message];
    };

    stable var followed: List.List<Principal> = List.nil();

    public shared func follow(id: Principal): async(){
        followed := List.push(id, followed);
    };

    public shared query func follows(): async [Principal]{
        List.toArray(followed);
    };

    stable var messages: List.List<Message> = List.nil();

    public shared (msg) func post(text: Text): async (){
        assert(Principal.toText(msg.caller) == "bwoy3-pze24-rjms4-vz2vo-etg4j-notgb-b3kmk-zog7c-7qb5f-6zbqn-mqe");
        let message: Message = {
            content = text;
            time = Time.now();
        };
        messages := List.push(message, messages);
    };
    
    public shared query func posts(since: Time.Time): async [Message]{
        List.toArray(List.filter<Message>(messages, func (msg){msg.time > since}))
    };

    public shared func timeline(since: Time.Time): async [Message]{
        var all: List.List<Message> = List.nil();
        for ( id in Iter.fromList(followed)){
            let canister: Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
            for (msg in Iter.fromArray(msgs)){
                all := List.push(msg, all);
            }
        };


        List.toArray(all)
    };
};

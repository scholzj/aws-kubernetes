#####
# Generates kubeadm token
#####

resource "random_shuffle" "token1" {
    seed = "${uuid()}${timestamp()}"
    input        = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i",
        "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]
    result_count = 6
}

resource "random_shuffle" "token2" {
    seed = "${timestamp()}${join("-", random_shuffle.token1.result)}${uuid()}"
    input        = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i",
        "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]
    result_count = 16
}

data "template_file" "kubeadm_token" {
    template   = "$${token1}.$${token2}"

    vars {
        token1 = "${join("", random_shuffle.token1.result)}"
        token2 = "${join("", random_shuffle.token2.result)}"
    }

    depends_on = [ "random_shuffle.token1", "random_shuffle.token1" ]
}

output "kubeadm_token" {
    value = "${data.template_file.kubeadm_token.rendered}"
}
